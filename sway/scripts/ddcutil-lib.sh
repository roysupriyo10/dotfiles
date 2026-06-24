#!/usr/bin/env bash
# Shared DDC/CI layer for sway scripts. Serializes all ddcutil I2C access.
# Source from sway/scripts/*.sh — do not execute directly.

DDC_CACHE_DIR="${DDC_CACHE_DIR:-/tmp/ddcutil-cache}"
DDC_LOCK_FILE="${DDC_LOCK_FILE:-/tmp/ddcutil.lock}"
DDC_BUS_CACHE_VALIDITY="${DDC_BUS_CACHE_VALIDITY:-300}"
DDC_AUDIO_CACHE_VALIDITY="${DDC_AUDIO_CACHE_VALIDITY:-3600}"
DDC_CMD_TIMEOUT="${DDC_CMD_TIMEOUT:-3}"
DDC_STATUS_BRIGHTNESS_AGE="${DDC_STATUS_BRIGHTNESS_AGE:-15}"

# Lock FD is opened once at source time; released automatically on process exit.
exec 200>"$DDC_LOCK_FILE"
_DDC_LOCK_DEPTH=0

ddc_ensure_cache_dir() {
  mkdir -p "$DDC_CACHE_DIR"
}

ddc_acquire_lock() {
  local max_wait="${1:-2}"
  ((_DDC_LOCK_DEPTH > 0)) && return 0
  if ! flock -w "$max_wait" 200; then
    return 1
  fi
  ((_DDC_LOCK_DEPTH++))
}

ddc_release_lock() {
  ((_DDC_LOCK_DEPTH <= 0)) && return 0
  ((_DDC_LOCK_DEPTH--))
  ((_DDC_LOCK_DEPTH > 0)) && return 0
  flock -u 200
}

ddc_locked() {
  local cmd_timeout="$1"; shift
  local rc=0
  if ! ddc_acquire_lock 2; then
    return 1
  fi
  timeout "$cmd_timeout" "$@" || rc=$?
  ddc_release_lock
  return "$rc"
}

ddc_cache_path() {
  printf '%s/%s' "$DDC_CACHE_DIR" "$1"
}

ddc_cache_get() {
  local key="$1" max_age="$2" path data ts val now age
  path=$(ddc_cache_path "$key")
  [[ -f "$path" ]] || return 1
  IFS=: read -r ts val <"$path"
  now=$(date +%s)
  age=$((now - ts))
  ((age <= max_age)) || return 1
  printf '%s' "$val"
}

ddc_cache_set() {
  local key="$1" value="$2"
  ddc_ensure_cache_dir
  printf '%s:%s\n' "$(date +%s)" "$value" >"$(ddc_cache_path "$key")"
}

ddc_parse_vcp() {
  sed -n 's/.*current value = *\([0-9][0-9]*\).*/\1/p' | head -1
}

ddc_detect_bus() {
  local output="$1" bus
  if ! ddc_acquire_lock 2; then
    return 1
  fi
  bus=$(timeout "$DDC_CMD_TIMEOUT" bash -c '
    ddcutil detect --enable-capabilities-cache 2>/dev/null \
      | grep -B 2 "DRM_connector.*$1" \
      | grep "I2C bus:" \
      | head -1 \
      | sed "s/.*\/dev\/i2c-\([0-9]*\).*/\1/"
  ' _ "$output") || true
  ddc_release_lock
  [[ -n "$bus" ]] || return 1
  printf '%s' "$bus"
}

ddc_bus_for_output() {
  local output="$1" bus
  bus=$(ddc_cache_get "${output}.bus" "$DDC_BUS_CACHE_VALIDITY") && {
    printf '%s' "$bus"
    return 0
  }
  bus=$(ddc_detect_bus "$output") || return 1
  ddc_cache_set "${output}.bus" "$bus"
  printf '%s' "$bus"
}

ddc_get_vcp() {
  local bus="$1" code="$2" val
  if ! ddc_acquire_lock 2; then
    return 1
  fi
  val=$(timeout "$DDC_CMD_TIMEOUT" bash -c '
    ddcutil --bus "$1" --enable-capabilities-cache getvcp "$2" 2>/dev/null \
      | sed -n "s/.*current value = *\([0-9][0-9]*\).*/\1/p" \
      | head -1
  ' _ "$bus" "$code") || true
  ddc_release_lock
  [[ -n "$val" ]] || return 1
  printf '%s' "$val"
}

ddc_set_vcp() {
  local bus="$1" code="$2" value="$3"
  ddc_locked "$DDC_CMD_TIMEOUT" ddcutil --bus "$bus" --enable-capabilities-cache setvcp "$code" "$value" 2>/dev/null
}

# Status bar only — never touches I2C.
ddc_read_cached_brightness() {
  local output="$1" max_age="${2:-$DDC_STATUS_BRIGHTNESS_AGE}"
  ddc_cache_get "${output}.brightness" "$max_age"
}

# max_age=0 forces a live read. On lock failure, returns the newest cached value if any.
ddc_get_brightness() {
  local output="$1" max_age="${2:-$DDC_STATUS_BRIGHTNESS_AGE}" bus val
  if ((max_age > 0)); then
    val=$(ddc_cache_get "${output}.brightness" "$max_age") && {
      printf '%s' "$val"
      return 0
    }
  fi
  bus=$(ddc_bus_for_output "$output") || {
    val=$(ddc_cache_get "${output}.brightness" 86400) && { printf '%s' "$val"; return 0; }
    return 1
  }
  val=$(ddc_get_vcp "$bus" 10) || {
    val=$(ddc_cache_get "${output}.brightness" 86400) && { printf '%s' "$val"; return 0; }
    return 1
  }
  ddc_cache_set "${output}.brightness" "$val"
  printf '%s' "$val"
}

ddc_set_brightness() {
  local output="$1" value="$2" bus
  bus=$(ddc_bus_for_output "$output") || return 1
  ddc_set_vcp "$bus" 10 "$value" || return 1
  ddc_cache_set "${output}.brightness" "$value"
}

ddc_output_has_audio() {
  local output="$1" cached bus
  if cached=$(ddc_cache_get "${output}.audio" "$DDC_AUDIO_CACHE_VALIDITY"); then
    [[ "$cached" == "1" ]]
    return
  fi
  bus=$(ddc_bus_for_output "$output") || return 1
  if ddc_locked "$DDC_CMD_TIMEOUT" ddcutil --bus "$bus" --enable-capabilities-cache capabilities 2>/dev/null \
      | grep -qE 'Feature: 62|Feature: 8D'; then
    ddc_cache_set "${output}.audio" 1
    return 0
  fi
  ddc_cache_set "${output}.audio" 0
  return 1
}

ddc_get_volume() {
  local output="$1" max_age="${2:-2}" bus val
  if ((max_age > 0)); then
    val=$(ddc_cache_get "${output}.volume" "$max_age") && {
      printf '%s' "$val"
      return 0
    }
  fi
  bus=$(ddc_bus_for_output "$output") || return 1
  val=$(ddc_get_vcp "$bus" 62) || return 1
  ddc_cache_set "${output}.volume" "$val"
  printf '%s' "$val"
}

ddc_set_volume() {
  local output="$1" value="$2" bus
  bus=$(ddc_bus_for_output "$output") || return 1
  ddc_set_vcp "$bus" 62 "$value" || return 1
  ddc_cache_set "${output}.volume" "$value"
}

ddc_toggle_mute() {
  local output="$1" bus mute_status
  bus=$(ddc_bus_for_output "$output") || return 1
  mute_status=$(ddc_get_vcp "$bus" 8D) || return 1
  if [[ "$mute_status" == "1" ]]; then
    ddc_set_vcp "$bus" 8D 2
  else
    ddc_set_vcp "$bus" 8D 1
  fi
}

ddc_external_outputs() {
  swaymsg -t get_outputs 2>/dev/null \
    | jq -r '.[] | select(.name | test("^eDP") | not) | .name'
}

ddc_cleanup_cache() {
  [[ -d "$DDC_CACHE_DIR" ]] || return 0
  find "$DDC_CACHE_DIR" \( -name '*.brightness' -o -name '*.volume' -o -name '*.audio' \) \
    -type f -mmin +1 -delete 2>/dev/null || true
  find "$DDC_CACHE_DIR" -name '*.bus' -type f -mmin +10 -delete 2>/dev/null || true
}
