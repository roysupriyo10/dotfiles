# Parse install/toolchain: CUSTOM + PKG entries.

. "$INSTALL_DIR/lib/tools/custom.sh"

pkg_tool() {
  linux_pkg="$1"
  cmd="$2"
  brew_pkg="${3:-$linux_pkg}"

  if command -v "$cmd" >/dev/null 2>&1; then
    return 0
  fi
  if ! pkg_install "$linux_pkg" "$brew_pkg"; then
    log "warning: failed to install $linux_pkg — skipping" >&2
    return 0
  fi
  install_env
}

apply_toolchain() {
  install_env

  toolchain="$INSTALL_DIR/toolchain"
  [ -f "$toolchain" ] || return 0

  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%%#*}"
    line=$(printf '%s' "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    [ -z "$line" ] && continue

    set -- $line
    kind="$1"
    shift

    case "$kind" in
      CUSTOM) run_custom_tool "$1" ;;
      PKG) pkg_tool "$1" "$2" "${3:-}" ;;
      *) log "warning: unknown toolchain entry: $line — skipping" >&2 ;;
    esac
  done < "$toolchain"

  install_env
}
