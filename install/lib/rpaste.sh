run_hook_rpaste() {
  local bridge="$DOTFILES/rpaste/rpaste"
  if [ ! -x "$bridge" ] || [ ! -f "$DOTFILES/rpaste/rpaste_agent.py" ]; then
    log "warning: rpaste submodule is incomplete" >&2
    return 1
  fi
  command -v python3 >/dev/null 2>&1 || pkg_install python python || return 1
  if [ "$OS" = Linux ]; then
    if [ "${RPASTE_NATIVE:-0}" = 1 ]; then
      "$bridge" real-xclip >/dev/null 2>&1 || pkg_install xclip || return 1
      command -v Xvfb >/dev/null 2>&1 || pkg_install xorg-server-xvfb || return 1
      command -v wl-paste >/dev/null 2>&1 || pkg_install wl-clipboard || return 1
    elif [ -n "${WAYLAND_DISPLAY:-}" ]; then
      command -v wl-paste >/dev/null 2>&1 || pkg_install wl-clipboard || return 1
    elif [ -n "${DISPLAY:-}" ]; then
      "$bridge" real-xclip >/dev/null 2>&1 || pkg_install xclip || return 1
    fi
  elif [ "$OS" = Darwin ] && [ "${RPASTE_NATIVE:-0}" = 1 ]; then
    "$bridge" inject-build || return 1
  fi
  # Profiles and source SSH access are handled by the launchers, not patched
  # on every install. RPASTE_NATIVE=0 allows a path-only installation.
  "$bridge" install --no-profile --no-check --no-native
  install_rpaste_ssh
}

install_rpaste_ssh() {
  # This feature-only drop-in must not depend on the ssh-server hardening hook
  # or on where an account stores its authorized keys.
  local config=/etc/ssh/sshd_config work
  command -v sshd >/dev/null 2>&1 || return 0
  [ -f "$config" ] || return 0
  if ! _ssh_peek "$config" grep -qiE '^[[:space:]]*Include[[:space:]]+(/etc/ssh/)?sshd_config\.d/\*' "$config"; then
    log "rpaste: $config needs an Include for sshd_config.d/*" >&2
    return 1
  fi
  work=$(mktemp -d)
  mkdir "$work/source"
  cp "$DOTFILES/ssh/sshd_config.d/50-rpaste.conf" "$work/source/"
  : > "$work/undo"
  if ! _ssh_install_root_dir "$work/source" /etc/ssh/sshd_config.d "$work/undo" "$work"; then
    _ssh_rollback "$work/undo"
    rm -rf "$work"
    return 1
  fi
  if [ -s "$work/undo" ]; then
    if _ssh_sudo sshd -t; then
      _ssh_reload_sshd
    else
      _ssh_rollback "$work/undo"
      rm -rf "$work"
      return 1
    fi
  fi
  rm -rf "$work"
}
