#!/usr/bin/env bash
# Smart brightness: laptop panel via brightnessctl, external monitors via DDC/CI.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=ddcutil-lib.sh
source "$SCRIPT_DIR/ddcutil-lib.sh"

LOG_FILE="/tmp/smart-brightness.log"
LOCK_FILE="/tmp/smart-brightness.lock"
LAPTOP_CACHE_DIR="/tmp/smart-brightness-cache"
LAPTOP_CACHE_VALIDITY=5
LAPTOP_OUTPUT="eDP-1"

# Drop overlapping keypresses instead of queueing them.
acquire_lock() {
  if mkdir "$LOCK_FILE" 2>/dev/null; then
    trap 'rm -rf "$LOCK_FILE"' EXIT
    return 0
  fi
  log "Another brightness change in progress, ignoring event"
  exit 0
}

log() {
  if [[ "${DEBUG:-0}" == "1" ]]; then
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >>"$LOG_FILE"
  fi
}

laptop_cache_get() {
  local path data ts val now age
  path="$LAPTOP_CACHE_DIR/${LAPTOP_OUTPUT}.cache"
  [[ -f "$path" ]] || return 1
  IFS=: read -r ts val <"$path"
  now=$(date +%s)
  age=$((now - ts))
  ((age <= LAPTOP_CACHE_VALIDITY)) || return 1
  printf '%s' "$val"
}

laptop_cache_set() {
  local value="$1"
  mkdir -p "$LAPTOP_CACHE_DIR"
  printf '%s:%s\n' "$(date +%s)" "$value" >"$LAPTOP_CACHE_DIR/${LAPTOP_OUTPUT}.cache"
}

get_focused_output() {
  swaymsg -t get_outputs | jq -r '.[] | select(.focused == true) | .name'
}

is_laptop() {
  [[ "$1" == eDP-* ]]
}

laptop_brightness_pct() {
  local current max
  current=$(brightnessctl g)
  max=$(brightnessctl m)
  echo $((current * 100 / max))
}

at_brightness_boundary() {
  local action="$1" value="$2"
  case "$action" in
    up)   ((value >= 100)) ;;
    down) ((value <= 0)) ;;
    *)    return 1 ;;
  esac
}

control_laptop_brightness() {
  local action="$1" step="$2" cached percent

  if cached=$(laptop_cache_get); then
    at_brightness_boundary "$action" "$cached" && return 0
  fi

  percent=$(laptop_brightness_pct)
  log "Laptop brightness: $action by $step% (current: $percent%)"
  at_brightness_boundary "$action" "$percent" && {
    laptop_cache_set "$percent"
    return 0
  }

  case "$action" in
    up)   brightnessctl s "${step}%+" ;;
    down) brightnessctl s "${step}%-" ;;
  esac

  percent=$(laptop_brightness_pct)
  laptop_cache_set "$percent"
  log "Laptop brightness now: $percent%"
}

control_external_brightness() {
  local action="$1" step="$2" output="$3" cached current new

  if cached=$(ddc_get_brightness "$output" "$LAPTOP_CACHE_VALIDITY" 2>/dev/null); then
    at_brightness_boundary "$action" "$cached" && return 0
  fi

  current=$(ddc_get_brightness "$output" 0) || {
    log "ERROR: Could not read brightness for $output"
    return 1
  }

  log "External brightness: $action by $step% on $output (current: $current%)"
  at_brightness_boundary "$action" "$current" && return 0

  case "$action" in
    up)
      new=$((current + step))
      ((new > 100)) && new=100
      ;;
    down)
      new=$((current - step))
      ((new < 0)) && new=0
      ;;
  esac

  ddc_set_brightness "$output" "$new" || {
    log "ERROR: Failed to set brightness on $output"
    return 1
  }
  log "External brightness on $output now: $new%"
}

set_brightness() {
  local value="$1" output
  acquire_lock
  output=$(get_focused_output)
  log "Setting brightness to $value% on $output"

  if is_laptop "$output"; then
    brightnessctl s "${value}%"
    laptop_cache_set "$value"
  else
    ddc_set_brightness "$output" "$value" || {
      log "ERROR: Failed to set brightness on $output"
      return 1
    }
  fi
}

main() {
  local action="$1" step="${2:-10}" output
  acquire_lock
  output=$(get_focused_output)
  log "Brightness $action step=$step on $output"

  if is_laptop "$output"; then
    control_laptop_brightness "$action" "$step"
  else
    control_external_brightness "$action" "$step" "$output"
  fi
}

usage() {
  cat <<'EOF'
Usage: smart-brightness.sh {up|down|set} [step|value]
  up/down  Adjust brightness by step (default 10)
  set      Set brightness to value (0-100)
EOF
}

if (($# < 1 || $# > 2)); then
  usage
  exit 1
fi

action="$1"
case "$action" in
  set)
    [[ $# -eq 2 ]] || { echo "Error: 'set' requires a value (0-100)"; exit 1; }
    value="$2"
    [[ "$value" =~ ^[0-9]+$ && "$value" -le 100 ]] || {
      echo "Error: brightness value must be 0-100"
      exit 1
    }
    ddc_cleanup_cache
    set_brightness "$value"
    ;;
  up|down)
    ddc_cleanup_cache
    main "$@"
    ;;
  *)
    usage
    exit 1
    ;;
esac
