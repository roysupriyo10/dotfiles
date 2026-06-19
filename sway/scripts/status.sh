#!/usr/bin/env bash
# Swaybar status line — composable, machine-agnostic segments.

set -uo pipefail

segment() {
  printf '%s: %s' "$1" "$2"
}

join_segments() {
  local sep=' | ' out='' part
  for part in "$@"; do
    [[ -z "$part" ]] && continue
    [[ -n "$out" ]] && out+="${sep}"
    out+="$part"
  done
  printf ' %s\n' "$out"
}

mute_label() {
  [[ "$1" == true || "$1" == 1 ]] && printf 'Muted' || printf 'Unmuted'
}

wp_device_name() {
  wpctl inspect "$1" 2>/dev/null \
    | sed -n 's/.*node.description = "\(.*\)"/\1/p' \
    | cut -c1-7 \
    | sed 's/[[:space:]]*$//'
}

mic_muted() {
  local id muted

  if muted=$(wpctl inspect @DEFAULT_AUDIO_SOURCE@ 2>/dev/null \
      | sed -n 's/.*\[ muted = \] \(.*\)/\1/p'); then
    [[ -n "$muted" ]] && { printf '%s' "$muted"; return; }
  fi

  id=$(pamixer --list-sources 2>/dev/null \
    | awk '/\*/ {gsub(/[^0-9]/, "", $1); print $1; exit}')
  if [[ -n "$id" ]]; then
    pamixer --source "$id" --get-mute 2>/dev/null && return
  fi

  printf 'false'
}

battery_sysfs() {
  local bat
  for bat in /sys/class/power_supply/BAT*; do
    [[ -f "$bat/capacity" ]] || continue
    printf '%s' "$bat"
    return
  done
}

battery_text() {
  local bat pct status
  bat=$(battery_sysfs) || return 0
  pct=$(<"$bat/capacity")
  status=$(<"$bat/status")
  [[ "$status" == "Charging" ]] && printf '%s%%+' "$pct" || printf '%s%%' "$pct"
}

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
  local output bus brightness parts=''

  while IFS= read -r output; do
    [[ -z "$output" ]] && continue
    bus=$(ddcutil detect --enable-capabilities-cache 2>/dev/null \
      | grep -B 2 "DRM_connector.*${output}" \
      | grep 'I2C bus:' \
      | head -1 \
      | sed 's/.*\/dev\/i2c-\([0-9]*\).*/\1/')
    [[ -z "$bus" ]] && continue

    brightness=$(ddcutil --bus "$bus" --enable-capabilities-cache getvcp 10 2>/dev/null \
      | grep -o 'current value = *[0-9]*' \
      | grep -o '[0-9]*' \
      | head -1)
    [[ -n "$brightness" ]] && parts+="${output}: ${brightness}% "
  done < <(swaymsg -t get_outputs 2>/dev/null \
    | jq -r '.[] | select(.name | test("^eDP") | not) | .name')

  printf '%s' "$parts"
}

light_text() {
  local laptop_pct=$1 internal=$2 external=$3

  if [[ -n "$external" && -n "$internal" ]]; then
    printf '%s: %s%% %s' "$internal" "$laptop_pct" "$external"
  else
    printf '%s%%' "$laptop_pct"
  fi
}

ram_pct() {
  local total available
  total=$(awk '/^MemTotal/ {print $2}' /proc/meminfo)
  available=$(awk '/^MemAvailable/ {print $2}' /proc/meminfo)
  echo $(((total - available) * 100 / total))
}

cpu_temp() {
  local t

  t=$(sensors 2>/dev/null | awk '
    /Package id 0:/ { gsub(/[^0-9.]/, "", $4); print $4; exit }
    /^Core 0:/      { gsub(/[^0-9.]/, "", $3); print $3; exit }
    /^temp1:/       { gsub(/[^0-9.]/, "", $2); print $2; exit }
  ')
  if [[ -n "$t" ]]; then
    printf '+%s°C' "$t"
    return
  fi

  if [[ -f /sys/class/thermal/thermal_zone0/temp ]]; then
    t=$(< /sys/class/thermal/thermal_zone0/temp)
    printf '+%s°C' "$(awk -v t="$t" 'BEGIN {printf "%.1f", t/1000}')"
  fi
}

# --- collect -----------------------------------------------------------------

date_formatted=$(date +"%Y-%m-%d %A %I:%M:%S %p")
connected_network=$(iwgetid -r 2>/dev/null || true)

volume_muted=$(pamixer --get-mute 2>/dev/null || echo false)
volume_percentage=$(pamixer --get-volume 2>/dev/null || echo 0)
mic_muted_flag=$(mic_muted)

sink_name=$(wp_device_name @DEFAULT_AUDIO_SINK@)
source_name=$(wp_device_name @DEFAULT_AUDIO_SOURCE@)

internal_output=$(internal_output_name)
laptop_pct=$(laptop_brightness_pct 2>/dev/null || echo '?')
external_brightness=$(external_brightness_text)

bat_text=$(battery_text)
temp_text=$(cpu_temp)
ram_text=$(ram_pct)

mic_label="${source_name} ($(mute_label "$mic_muted_flag"))"
out_label="${sink_name} ($(mute_label "$volume_muted"))"
vol_label="${volume_percentage}%"
light_label=$(light_text "$laptop_pct" "$internal_output" "$external_brightness")

parts=()
parts+=("$(segment Network "$connected_network")")
parts+=("$(segment Light "$light_label")")
parts+=("$(segment Mic "$mic_label")")
parts+=("$(segment Out "$out_label")")
parts+=("$(segment Vol "$vol_label")")
[[ -n "$temp_text" ]] && parts+=("$(segment Temp "$temp_text")")
parts+=("$(segment RAM "${ram_text}%")")
[[ -n "$bat_text" ]] && parts+=("$(segment BAT "$bat_text")")
parts+=(" ${date_formatted}")

join_segments "${parts[@]}"
