#!/usr/bin/env bash
#
# apply-monitors.sh — runtime monitor configuration for Sway
#
# What it does:
#   * Picks the BEST mode for every connected output (highest resolution,
#     then highest refresh rate) by reading sway's own reported mode list, so
#     there are never any fragile "2560x1440@143.991Hz" strings to keep in sync.
#   * Places outputs left-to-right in the order given by $monitor_order.
#   * Anchors every output at y=0 (top edges aligned).
#   * Scales each output from $monitor_scales, or auto by resolution
#     (>=1440p -> 1.6, otherwise 1.0) when no override is given.
#
# Works for any number of displays (1, 2, 3+). The only knobs you normally
# touch live in:  config.d/variables.d/03-displays.conf
#
# Run on startup (exec in 99-autostart.conf) and on every reload
# (Super+Shift+C). Safe to run repeatedly.

set -euo pipefail

DISPLAYS_CONF="${DISPLAYS_CONF:-$HOME/.config/sway/config.d/variables.d/03-displays.conf}"

log() { echo "[apply-monitors] $*" >&2; }

# Read a `set $name value` knob from the displays conf, with a fallback default.
get_knob() {
    local name="$1" default="$2" val
    val=$(grep -E "^set [$]${name}[[:space:]]" "$DISPLAYS_CONF" 2>/dev/null \
          | head -1 | sed -E "s/^set [$]${name}[[:space:]]+//" | tr -d '"' | xargs || true)
    echo "${val:-$default}"
}

read -ra ORDER <<< "$(get_knob monitor_order "")"

# Parse "name=scale name=scale ..." into an associative array.
declare -A SCALE_OVERRIDE=()
for pair in $(get_knob monitor_scales ""); do
    SCALE_OVERRIDE["${pair%%=*}"]="${pair#*=}"
done

# Per-output scale: explicit override wins, else auto by height.
scale_for() {
    local name="$1" height="$2"
    if [ -n "${SCALE_OVERRIDE[$name]:-}" ]; then
        echo "${SCALE_OVERRIDE[$name]}"
    elif [ "$height" -ge 1440 ]; then
        echo "1.6"
    else
        echo "1.0"
    fi
}

# Effective (scaled) width in logical pixels, rounded to an integer.
eff_width() {
    awk -v w="$1" -v s="$2" 'BEGIN { printf "%d", (w / s) + 0.5 }'
}

# Apply mode+scale+position to one output, falling back to the preferred mode
# if the chosen mode is somehow rejected.
apply_output() {
    local name="$1" mode="$2" scale="$3" x="$4" y="$5"
    log "$name -> mode $mode scale $scale position $x,$y"
    if ! swaymsg output "$name" mode "$mode" scale "$scale" position "$x" "$y" >/dev/null 2>&1; then
        log "mode '$mode' rejected on $name; keeping preferred mode"
        swaymsg output "$name" scale "$scale" position "$x" "$y" >/dev/null 2>&1 \
            || log "failed to configure $name"
    fi
}

# Collect the best mode for every CONNECTED output into lookup maps.
declare -A MODE WIDTH HEIGHT
while IFS='|' read -r name mode w h; do
    [ -n "$name" ] || continue
    MODE["$name"]="$mode"; WIDTH["$name"]="$w"; HEIGHT["$name"]="$h"
done < <(swaymsg -t get_outputs | jq -r '
    .[]
    | select(.modes != null and (.modes | length > 0))
    | .name as $n
    | (.modes | max_by(.width * .height * 1000000 + .refresh)) as $m
    | "\($n)|\($m.width)x\($m.height)@\($m.refresh / 1000)Hz|\($m.width)|\($m.height)"')

if [ "${#MODE[@]}" -eq 0 ]; then
    log "no connected outputs found"
    exit 0
fi

# Build the left-to-right placement: listed-and-connected first (in order),
# then any connected output not in the list, appended on the right (sorted for
# determinism).
declare -A PLACED=()
placement=()
for name in "${ORDER[@]}"; do
    if [ -n "${MODE[$name]:-}" ] && [ -z "${PLACED[$name]:-}" ]; then
        placement+=("$name"); PLACED["$name"]=1
    fi
done
while IFS= read -r name; do
    if [ -z "${PLACED[$name]:-}" ]; then
        placement+=("$name"); PLACED["$name"]=1
    fi
done < <(printf '%s\n' "${!MODE[@]}" | sort)

# Lay them out left-to-right, all anchored at y=0.
x=0
for name in "${placement[@]}"; do
    scale=$(scale_for "$name" "${HEIGHT[$name]}")
    apply_output "$name" "${MODE[$name]}" "$scale" "$x" 0
    x=$(( x + $(eff_width "${WIDTH[$name]}" "$scale") ))
done
