#!/usr/bin/env bash
# Smart volume: laptop audio via pactl, external monitor speakers via DDC/CI.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=ddcutil-lib.sh
source "$SCRIPT_DIR/ddcutil-lib.sh"

LOG_FILE="/tmp/smart-volume.log"
LOCK_FILE="/tmp/smart-volume.lock"
LAPTOP_CACHE_DIR="/tmp/smart-volume-cache"
LAPTOP_CACHE_VALIDITY=2

acquire_lock() {
  local count=0
  while ((count < 20)); do
    if mkdir "$LOCK_FILE" 2>/dev/null; then
      trap 'rm -rf "$LOCK_FILE"' EXIT
      return 0
    fi
    sleep 0.1
    ((count++)) || true
  done
  echo "Another volume change in progress, skipping"
  exit 0
}

log() {
  if [[ "${DEBUG:-0}" == "1" ]]; then
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >>"$LOG_FILE"
  fi
}

laptop_cache_get() {
  local path data ts val now age
  path="$LAPTOP_CACHE_DIR/laptop_volume.cache"
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
  printf '%s:%s\n' "$(date +%s)" "$value" >"$LAPTOP_CACHE_DIR/laptop_volume.cache"
}

get_focused_output() {
  swaymsg -t get_outputs | jq -r '.[] | select(.focused == true) | .name'
}

is_laptop() {
  [[ "$1" == eDP-* ]]
}

get_volume() {
  pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null \
    | grep -o '[0-9]*%' | head -1 | tr -d '%'
}

is_muted() {
  pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | grep -q 'yes'
}

at_volume_boundary() {
  local action="$1" value="$2"
  case "$action" in
    up)   ((value >= 100)) ;;
    down) ((value <= 0)) ;;
    *)    return 1 ;;
  esac
}

control_laptop_volume() {
  local action="$1" step="${2:-5}" cached current new_volume

  if cached=$(laptop_cache_get); then
    at_volume_boundary "$action" "$cached" && return 0
  fi

  case "$action" in
    mute)
      pactl set-sink-mute @DEFAULT_SINK@ toggle
      log "Laptop audio mute toggled"
      return 0
      ;;
    set)
      pactl set-sink-volume @DEFAULT_SINK@ "${step}%"
      laptop_cache_set "$step"
      log "Laptop volume set to $step%"
      return 0
      ;;
  esac

  current=$(get_volume)
  log "Laptop volume: $action by $step% (current: $current%)"
  at_volume_boundary "$action" "$current" && {
    laptop_cache_set "$current"
    return 0
  }

  case "$action" in
    up)   pactl set-sink-volume @DEFAULT_SINK@ "+${step}%" ;;
    down) pactl set-sink-volume @DEFAULT_SINK@ "-${step}%" ;;
  esac

  new_volume=$(get_volume)
  laptop_cache_set "$new_volume"
  log "Laptop volume now: $new_volume%"
}

control_external_volume() {
  local action="$1" step="${2:-5}" output="$3" cached current new

  if ! ddc_output_has_audio "$output"; then
    log "Monitor $output has no DDC audio; using laptop audio"
    control_laptop_volume "$action" "$step"
    return
  fi

  if cached=$(ddc_get_volume "$output" "$LAPTOP_CACHE_VALIDITY" 2>/dev/null); then
    at_volume_boundary "$action" "$cached" && return 0
  fi

  case "$action" in
    mute)
      ddc_toggle_mute "$output" || {
        log "Failed to toggle monitor mute; using laptop audio"
        control_laptop_volume mute
      }
      return 0
      ;;
    set)
      ddc_set_volume "$output" "$step" || {
        log "Failed to set monitor volume; using laptop audio"
        control_laptop_volume set "$step"
      }
      return 0
      ;;
  esac

  current=$(ddc_get_volume "$output" 0) || {
    log "Could not read monitor volume; using laptop audio"
    control_laptop_volume "$action" "$step"
    return
  }

  log "External volume: $action by $step% on $output (current: $current%)"
  at_volume_boundary "$action" "$current" && return 0

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

  ddc_set_volume "$output" "$new" || {
    log "Failed to set monitor volume; using laptop audio"
    control_laptop_volume "$action" "$step"
  }
}

set_volume() {
  local value="$1" output
  acquire_lock
  output=$(get_focused_output)
  log "Setting volume to $value% on $output"

  if is_laptop "$output"; then
    control_laptop_volume set "$value"
  else
    control_external_volume set "$value" "$output"
  fi
}

main() {
  local action="$1" step="${2:-5}" output
  acquire_lock
  output=$(get_focused_output)
  log "Volume $action step=$step on $output"

  if is_laptop "$output"; then
    control_laptop_volume "$action" "$step"
  else
    control_external_volume "$action" "$step" "$output"
  fi
}

usage() {
  cat <<'EOF'
Usage: smart-volume.sh {up|down|mute|set} [step|value]
  up/down  Adjust volume by step (default 5)
  mute     Toggle mute
  set      Set volume to value (0-100)
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
      echo "Error: volume value must be 0-100"
      exit 1
    }
    ddc_cleanup_cache
    set_volume "$value"
    ;;
  up|down|mute)
    ddc_cleanup_cache
    main "$@"
    ;;
  *)
    usage
    exit 1
    ;;
esac
