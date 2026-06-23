#!/bin/sh
# Dotfiles bootstrap orchestrator.
#
# Phases:
#   1. submodules (init missing only)
#   2. lndir
#   3. manifest: LINK + MIRROR
#   4. toolchain (fnm/node, pnpm, rustup, PKG tools, tm)
#   5. manifest: HOOK (cursor — needs jq from toolchain)
#
# Flags:
#   --migrate-tm   run `tm migrate` after building tm
set -e

INSTALL_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
DOTFILES="$(CDPATH= cd -- "$INSTALL_DIR/.." && pwd)"
OS="$(uname)"
PNPM_HOME="${PNPM_HOME:-$HOME/.local/share/pnpm}"
FNM_DIR="${FNM_DIR:-$HOME/.local/share/fnm}"
MIGRATE_TM=0

for arg in "$@"; do
  case "$arg" in
    --migrate-tm) MIGRATE_TM=1 ;;
    *)
      log "unknown flag: $arg" >&2
      exit 1
      ;;
  esac
done

# shellcheck source=lib/common.sh
. "$INSTALL_DIR/lib/common.sh"
# shellcheck source=lib/pkg.sh
. "$INSTALL_DIR/lib/pkg.sh"
# shellcheck source=lib/submodules.sh
. "$INSTALL_DIR/lib/submodules.sh"
# shellcheck source=lib/lndir.sh
. "$INSTALL_DIR/lib/lndir.sh"
# shellcheck source=lib/cursor.sh
. "$INSTALL_DIR/lib/cursor.sh"
# shellcheck source=lib/manifest.sh
. "$INSTALL_DIR/lib/manifest.sh"
# shellcheck source=lib/toolchain.sh
. "$INSTALL_DIR/lib/toolchain.sh"

cd "$DOTFILES"

ensure_submodules
ensure_lndir

if ! have_lndir; then
  log "lndir not available after install" >&2
  exit 1
fi

apply_manifest_sync
apply_toolchain

if [ "$MIGRATE_TM" = 1 ]; then
  migrate_tmux_manager_config
fi

apply_manifest_hooks

log "done."
