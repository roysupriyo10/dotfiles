# Parse install/toolchain: CUSTOM + PKG entries.

. "$INSTALL_DIR/lib/tools/custom.sh"

_process_toolchain_line() {
  line=$1
  line=$(expand_manifest_line "$line")

  set -- $line
  if [ "$1" = LINUX ] || [ "$1" = DARWIN ]; then
    prefix=$1
    shift
    platform_matches "$prefix" || return 0
  fi

  kind=$1
  shift

  case "$kind" in
    CUSTOM) run_custom_tool "$1" ;;
    PKG) pkg_tool "$1" "$2" "${3:-}" ;;
    *) log "warning: unknown toolchain entry: $line — skipping" >&2 ;;
  esac
}

pkg_tool() {
  linux_pkg=$1
  cmd=$2
  brew_pkg=${3:-$linux_pkg}

  if command -v "$cmd" >/dev/null 2>&1; then
    return 0
  fi
  if ! pkg_install "$linux_pkg" "$brew_pkg"; then
    log "warning: failed to install $linux_pkg — skipping" >&2
    return 0
  fi
}

apply_toolchain() {
  install_env

  toolchain="$INSTALL_DIR/toolchain"
  each_config_line "$toolchain" _process_toolchain_line

  install_env
}
