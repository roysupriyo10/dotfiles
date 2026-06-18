#!/usr/bin/env bash
#
# Reload the Sway configuration and re-apply monitor layout.
# Bound to Super+Shift+C.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Reload static config (backgrounds, keybindings, ...).
swaymsg reload >/dev/null

# Re-select best modes and re-apply the left/right layout.
"$SCRIPT_DIR/apply-monitors.sh"
