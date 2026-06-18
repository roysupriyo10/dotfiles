#!/usr/bin/env bash
# Region/full screenshots for grim + slurp (Sway keybindings).

set -euo pipefail

SCREENSHOTS="${SCREENSHOTS_DIR:-$HOME/Pictures/Screenshots}"
# Sway's set $screenshots uses ~; env/vars do not expand it (may become /home/.../~/...).
SCREENSHOTS="${SCREENSHOTS/#\~/$HOME}"
SCREENSHOTS="${SCREENSHOTS//\/~\//\/}"

MODE="${1:-area-file}"
SLURP_FMT='%x,%y %wx%h'

mkdir -p "$SCREENSHOTS"

read_slurp_area() {
    local area
    area="$(slurp -f "$SLURP_FMT")" || return 1
    [[ -n "$area" ]] || return 1
    printf '%s' "$area"
}

case "$MODE" in
    area-file)
        area="$(read_slurp_area)" || exit 0
        grim -g "$area" "$SCREENSHOTS/$(date +%d-%m-%y_%H-%M-%S).png"
        ;;
    area-clipboard)
        area="$(read_slurp_area)" || exit 0
        grim -g "$area" - | wl-copy
        ;;
    full-file)
        grim "$SCREENSHOTS/$(date +%d-%m-%y_%H-%M-%S).png"
        ;;
    full-clipboard)
        grim - | wl-copy
        ;;
    *)
        echo "usage: $0 [area-file|area-clipboard|full-file|full-clipboard]" >&2
        exit 1
        ;;
esac
