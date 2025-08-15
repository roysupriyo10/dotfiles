#!/bin/bash

# Sway Configuration Reload Script
# Ensures monitor positions are generated before reloading configuration

set -euo pipefail

SCRIPT_DIR="$(dirname "$0")"
GENERATE_SCRIPT="$SCRIPT_DIR/generate-positions.sh"

# Generate monitor positions first
"$GENERATE_SCRIPT"

# Then reload Sway configuration
swaymsg reload