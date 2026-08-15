#!/usr/bin/env bash

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=ddcutil-lib.sh
source "$SCRIPT_DIR/ddcutil-lib.sh"

laptop_brightness_pct() {
  local max current
  max=$(brightnessctl m 2>/dev/null | awk '{print $1}') || return 1
  current=$(brightnessctl g 2>/dev/null | awk '{print $1}') || return 1
  [[ -n "$max" && "$max" -gt 0 ]] || return 1
  echo $((current * 100 / max))
}

internal_output_name() {
  swaymsg -t get_outputs 2>/dev/null \
    | jq -r '.[] | select(.name | test("^eDP")) | .name' \
    | head -1
}

external_brightness_text() {
  local output brightness parts=''

  while IFS= read -r output; do
    [[ -z "$output" ]] && continue
    brightness=$(ddc_get_brightness "$output" "$DDC_STATUS_BRIGHTNESS_AGE" 2>/dev/null) || continue
    parts+="${output}: ${brightness}% "
  done < <(ddc_external_outputs)

  printf '%s' "$parts"
}

laptop_pct=$(laptop_brightness_pct 2>/dev/null || echo '?')
internal=$(internal_output_name)
external=$(external_brightness_text)

if [[ -n "$external" && -n "$internal" ]]; then
  printf '%s: %s%% %s\n' "$internal" "$laptop_pct" "$external"
else
  printf '%s%%\n' "$laptop_pct"
fi
