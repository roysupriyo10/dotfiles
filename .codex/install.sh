#!/bin/sh
set -eu
INSTALL_DIR="$(CDPATH= cd -- "$(dirname "$0")/../install" && pwd)"
DOTFILES="$(CDPATH= cd -- "$INSTALL_DIR/.." && pwd)"
. "$INSTALL_DIR/lib/common.sh"
. "$INSTALL_DIR/lib/codex.sh"
run_hook_codex
