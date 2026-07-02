#!/bin/sh
set -e
INSTALL_DIR="$(CDPATH= cd -- "$(dirname "$0")/../install" && pwd)"
DOTFILES="$(CDPATH= cd -- "$INSTALL_DIR/.." && pwd)"
OS="$(uname)"
# shellcheck source=../install/lib/common.sh
. "$INSTALL_DIR/lib/common.sh"
# shellcheck source=../install/lib/claude.sh
. "$INSTALL_DIR/lib/claude.sh"
run_hook_claude
