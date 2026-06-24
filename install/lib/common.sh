# Shared install helpers. Expects INSTALL_DIR, DOTFILES, OS, HOME from run.sh.

log() {
  printf 'install.sh: %s\n' "$*"
}

# Expand ${HOME} in manifest lines before word-splitting.
expand_manifest_line() {
  printf '%s' "$1" | sed "s|\${HOME}|$HOME|g"
}

# Resolve dest paths to absolute paths. Rejects relative results.
resolve_dest() {
  path=$1
  path=${path//\$\{HOME\}/$HOME}
  case "$path" in
    ~/*) path="$HOME${path#~}" ;;
    ~) path="$HOME" ;;
  esac
  case "$path" in
    /*) printf '%s' "$path" ;;
    *)
      log "path is not absolute (use \${HOME}/...): $1" >&2
      return 1
      ;;
  esac
}

abspath() {
  target=$1
  case "$target" in
    /*) printf '%s' "$target" ;;
    *)
      CDPATH= cd -- "$(dirname "$target")" 2>/dev/null || return 1
      printf '%s/%s' "$(pwd)" "$(basename "$target")"
      ;;
  esac
}

_ensure_symlink_abs() {
  link_src=$1
  link_dst=$2
  mkdir -p "$(dirname "$link_dst")"
  if [ -L "$link_dst" ] && [ "$(readlink "$link_dst")" = "$link_src" ]; then
    return 0
  fi
  ln -sf "$link_src" "$link_dst"
}

ensure_symlink() {
  link_src=$(abspath "$1") || return 1
  link_dst=$(resolve_dest "$2") || return 1
  _ensure_symlink_abs "$link_src" "$link_dst"
}

ensure_mirror() {
  mirror_src=$(abspath "$1") || return 1
  mirror_dst=$(resolve_dest "$2") || return 1

  if [ ! -d "$mirror_src" ]; then
    log "warning: mirror source missing, skipping: $mirror_src" >&2
    return 0
  fi

  mkdir -p "$mirror_dst"
  lndir -silent "$mirror_src" "$mirror_dst" 2>/dev/null || true

  (
    cd "$mirror_src" || exit 0
    find . -type f ! -path './.git/*' -print | while IFS= read -r rel; do
      rel="${rel#./}"
      [ -n "$rel" ] || continue
      _ensure_symlink_abs "$mirror_src/$rel" "$mirror_dst/$rel"
    done
  )
}

platform_matches() {
  prefix="$1"
  case "$prefix" in
    LINUX) [ "$OS" = Linux ] ;;
    DARWIN) [ "$OS" = Darwin ] ;;
    *) return 1 ;;
  esac
}

# kitty/ssh.conf must live under ~/.config/kitty/ — not ~/.ssh/.
verify_kitty_ssh_conf() {
  src="$DOTFILES/kitty/ssh.conf"
  dst="$HOME/.config/kitty/ssh.conf"
  [ -f "$src" ] || return 0

  if [ ! -L "$dst" ] || [ "$(readlink "$dst")" != "$src" ]; then
    ensure_symlink "$src" "$dst" 2>/dev/null || true
  fi

  if [ -f "$dst" ] && grep -qE '^[[:space:]]*copy_kitten\b' "$dst" 2>/dev/null; then
    log "warning: $dst still has obsolete copy_kitten — git pull dotfiles and re-run install.sh" >&2
  fi
}
