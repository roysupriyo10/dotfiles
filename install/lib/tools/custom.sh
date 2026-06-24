# CUSTOM toolchain dispatcher — handlers live in lib/tools/*.sh

. "$INSTALL_DIR/lib/tools/fnm.sh"
. "$INSTALL_DIR/lib/tools/pnpm.sh"
. "$INSTALL_DIR/lib/tools/rustup.sh"
. "$INSTALL_DIR/lib/tools/tmux-manager.sh"

run_custom_tool() {
  case "$1" in
    fnm) custom_fnm ;;
    pnpm) custom_pnpm ;;
    rustup) custom_rustup ;;
    tmux-manager) custom_tmux_manager ;;
    *)
      log "warning: unknown custom tool: $1 — skipping" >&2
      return 0
      ;;
  esac
}
