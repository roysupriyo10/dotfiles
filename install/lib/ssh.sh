# SSH keepalive + hardening — lib/ssh.sh
#
# ssh-server: copies the repo's ssh/sshd_config.d/*.conf into
#   /etc/ssh/sshd_config.d/ and, on Linux, ssh/sysctl.d/*.conf into
#   /etc/sysctl.d/ (macOS has no sysctl.d and none of those keys).
# ssh-client: copies ssh/config.d/resilience.conf into ~/.ssh/config.d/ and
#   appends one marked Include block to ~/.ssh/config.
#
# Additive: only files named after the ones in this repo are ever written.
# sshd_config, ~/.ssh/config content and other drop-ins are never edited, and
# both sshd and ssh take the first value they see, so existing settings win.
# AuthenticationMethods is the exception — it would switch off password logins
# another drop-in turns on — so 40-hardening.conf stays off such a host.
#
# Idempotent: a file is written only when it differs from the repo copy, and
# sshd is reloaded only when something changed. A re-run needs sudo only to
# look into a root-only /etc/ssh (Fedora family).
#
# Safe: the result is checked with `sshd -t` before the reload; on failure
# every file written by this run is put back the way it was. A reload keeps
# established sessions. macOS needs no reload: launchd starts a fresh sshd per
# connection, so the next login reads the new files.
#
# Files are copied, not symlinked: they are root-owned in /etc, and ssh refuses
# a client config that is group/world-writable.

SSH_CLIENT_MARK_BEGIN="# >>> dotfiles ssh-client >>>"
SSH_CLIENT_MARK_END="# <<< dotfiles ssh-client <<<"

# _ssh_sudo <cmd...> — root runs directly; otherwise sudo.
_ssh_sudo() {
  if [ "$(id -u)" = 0 ]; then
    "$@"
  else
    sudo "$@"
  fi
}

# _ssh_peek <path> <cmd...> — run a read-only command that has to see <path>.
# Fedora-family hosts keep sshd_config and sshd_config.d root-only; elsewhere
# no sudo is used.
_ssh_peek() {
  peek_path=$1
  shift
  if [ -r "$peek_path" ] || [ ! -e "$peek_path" ]; then
    "$@"
  else
    _ssh_sudo "$@"
  fi
}

# _ssh_host_password_dropin <sshd_config.d> — print the first drop-in there
# that turns password logins on. Ours never do, so a hit is the host's own.
_ssh_host_password_dropin() {
  _ssh_peek "$1" sh -c '
    grep -liE "^[[:space:]]*(PasswordAuthentication|KbdInteractiveAuthentication|ChallengeResponseAuthentication)[[:space:]]+yes" "$1"/* 2>/dev/null | head -n 1
  ' sh "$1" | grep .
}

# Restore what _ssh_install_root_dir replaced, using the undo list it wrote.
_ssh_rollback() {
  undo=$1
  while IFS='|' read -r dst backup; do
    [ -n "$dst" ] || continue
    if [ -n "$backup" ]; then
      _ssh_sudo install -m 644 -o 0 -g 0 "$backup" "$dst" || true
    else
      _ssh_sudo rm -f "$dst" || true
    fi
  done < "$undo"
}

# _ssh_install_root_dir <src-dir> <dst-dir> <undo-list> <backup-dir>
# Copies changed *.conf files and records each as "dst|backup" ("dst|" when
# the file is new). Returns 1 when a write failed.
_ssh_install_root_dir() {
  src_dir=$1
  dst_dir=$2
  undo=$3
  backup_dir=$4

  for src in "$src_dir"/*.conf; do
    [ -f "$src" ] || continue
    dst="$dst_dir/$(basename "$src")"
    if _ssh_peek "$dst_dir" cmp -s "$src" "$dst" 2>/dev/null; then
      continue
    fi

    backup=""
    if _ssh_peek "$dst_dir" test -e "$dst"; then
      backup="$backup_dir/$(basename "$dst_dir").$(basename "$dst")"
      _ssh_peek "$dst_dir" cp "$dst" "$backup" || return 1
    fi
    log "installing $dst"
    # Numeric ids and no -D: root's group is "wheel" on macOS, and BSD
    # install has no -D.
    _ssh_sudo mkdir -p "$dst_dir" || return 1
    _ssh_sudo install -m 644 -o 0 -g 0 "$src" "$dst" || return 1
    printf '%s|%s\n' "$dst" "$backup" >> "$undo"
  done
  return 0
}

_ssh_reload_sshd() {
  [ "$OS" = Linux ] || return 0
  command -v systemctl >/dev/null 2>&1 || return 0
  for unit in sshd ssh; do
    if systemctl is-active --quiet "$unit" 2>/dev/null; then
      log "reloading $unit"
      _ssh_sudo systemctl reload "$unit" || log "warning: $unit reload failed" >&2
      return 0
    fi
  done
  log "sshd not running — new config applies when it starts"
}

run_hook_ssh_server() {
  case "$OS" in
    Linux | Darwin) ;;
    *) return 0 ;;
  esac

  src_sshd="$DOTFILES/ssh/sshd_config.d"
  src_sysctl="$DOTFILES/ssh/sysctl.d"
  dst_sshd="/etc/ssh/sshd_config.d"
  sshd_config="/etc/ssh/sshd_config"

  if ! command -v sshd >/dev/null 2>&1 || [ ! -f "$sshd_config" ]; then
    log "sshd not installed — skipping ssh-server hook"
    return 0
  fi

  if [ "$(id -u)" != 0 ] && ! command -v sudo >/dev/null 2>&1; then
    log "warning: sudo required for ssh-server hook — skipping" >&2
    return 0
  fi

  # Drop-ins only take effect through this Include; adding it would mean
  # editing sshd_config, which this hook never does. Linux distros include
  # sshd_config.d/*.conf, macOS sshd_config.d/*.
  if ! _ssh_peek "$sshd_config" grep -qiE '^[[:space:]]*Include[[:space:]]+(/etc/ssh/)?sshd_config\.d/\*' "$sshd_config" 2>/dev/null; then
    log "warning: $sshd_config does not include sshd_config.d/* — skipping ssh-server hook" >&2
    return 0
  fi

  # 40-hardening.conf turns off everything but public keys. Never install it
  # for a user who would then have no way back in.
  if [ ! -s "$HOME/.ssh/authorized_keys" ]; then
    log "warning: $HOME/.ssh/authorized_keys is empty — skipping ssh-server hook (would lock you out)" >&2
    return 0
  fi

  work=$(mktemp -d) || return 0
  : > "$work/sshd.undo"
  : > "$work/sysctl.undo"

  # Password logins a host drop-in turns on are the admin's decision; keys-only
  # would undo it, so that host gets everything but the hardening.
  mkdir "$work/source"
  cp "$src_sshd"/*.conf "$work/source/"
  if host_dropin=$(_ssh_host_password_dropin "$dst_sshd"); then
    log "$(basename "$host_dropin") enables password logins — leaving 40-hardening.conf off this host"
    rm -f "$work/source/40-hardening.conf"
  fi

  if ! _ssh_install_root_dir "$work/source" "$dst_sshd" "$work/sshd.undo" "$work"; then
    log "warning: could not write to $dst_sshd — rolling back" >&2
    _ssh_rollback "$work/sshd.undo"
    rm -rf "$work"
    return 0
  fi

  if [ -s "$work/sshd.undo" ]; then
    if _ssh_sudo sshd -t; then
      _ssh_reload_sshd
    else
      log "warning: sshd rejected the new config — rolling back, sshd left untouched" >&2
      _ssh_rollback "$work/sshd.undo"
    fi
  else
    log "sshd drop-ins already up to date"
  fi

  if [ "$OS" = Linux ]; then
    if _ssh_install_root_dir "$src_sysctl" /etc/sysctl.d "$work/sysctl.undo" "$work"; then
      while IFS='|' read -r dst _; do
        [ -n "$dst" ] || continue
        _ssh_sudo sysctl -q -p "$dst" || log "warning: sysctl -p $dst failed" >&2
      done < "$work/sysctl.undo"
    else
      log "warning: could not write to /etc/sysctl.d — rolling back" >&2
      _ssh_rollback "$work/sysctl.undo"
    fi
  fi

  rm -rf "$work"
}

run_hook_ssh_client() {
  src="$DOTFILES/ssh/config.d/resilience.conf"
  ssh_dir="$HOME/.ssh"
  dst="$ssh_dir/config.d/dotfiles-resilience.conf"
  config="$ssh_dir/config"

  [ -f "$src" ] || return 0
  if ! command -v ssh >/dev/null 2>&1; then
    log "ssh not in PATH — skipping ssh-client hook"
    return 0
  fi

  mkdir -p "$ssh_dir/config.d"
  chmod 700 "$ssh_dir"

  if [ ! -f "$dst" ] || ! cmp -s "$src" "$dst"; then
    log "installing $dst"
    install -m 600 "$src" "$dst"
  fi

  if [ -f "$config" ] && grep -qF "$SSH_CLIENT_MARK_BEGIN" "$config"; then
    return 0
  fi

  log "adding Include block to $config"
  if [ ! -e "$config" ]; then
    ( umask 077 && : > "$config" )
  fi
  # Appended last, and under "Match all" so it closes whatever Host block the
  # file ends with instead of becoming part of it.
  {
    if [ -s "$config" ] && [ -n "$(tail -c 1 "$config")" ]; then
      printf '\n'
    fi
    printf '\n%s\nMatch all\n  Include %s\n%s\n' \
      "$SSH_CLIENT_MARK_BEGIN" "$dst" "$SSH_CLIENT_MARK_END"
  } >> "$config"
}
