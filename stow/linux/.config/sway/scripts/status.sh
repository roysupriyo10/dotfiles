#!/bin/bash
# Sway status bar script
# Reads all values from sysfs/procfs and wpctl (instant, no slow commands)

# --- Date ---
date_formatted=$(date +"%Y-%m-%d %A %I:%M:%S %p")

# --- Battery ---
battery_status=$(cat /sys/class/power_supply/BAT1/status 2>/dev/null)
battery_percentage=$(cat /sys/class/power_supply/BAT1/capacity 2>/dev/null)%
[[ "$battery_status" == "Charging" ]] && battery_percentage="${battery_percentage}+"

# --- Volume (wpctl / pipewire) ---
vol_info=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)
# Output format: "Volume: 0.65" or "Volume: 0.65 [MUTED]"
volume_raw=$(echo "$vol_info" | awk '{print $2}')
volume_percentage=$(awk "BEGIN {printf \"%d\", $volume_raw * 100}" 2>/dev/null || echo "?")
if echo "$vol_info" | grep -q MUTED; then
    volume_muted_display="Muted"
else
    volume_muted_display="Unmuted"
fi

# --- Mic mute status (wpctl / pipewire) ---
mic_info=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null)
if echo "$mic_info" | grep -q MUTED; then
    mic_muted_display="Muted"
else
    mic_muted_display="Unmuted"
fi

# --- Brightness (sysfs - instant reads) ---
# Laptop backlight: first non-ddcci device in /sys/class/backlight/
laptop_brightness=""
for dev in /sys/class/backlight/*; do
    devname=$(basename "$dev" 2>/dev/null)
    if [[ "$devname" != ddcci* ]] && [[ -f "$dev/brightness" ]]; then
        cur=$(cat "$dev/brightness" 2>/dev/null)
        max=$(cat "$dev/max_brightness" 2>/dev/null)
        if [[ -n "$cur" ]] && [[ -n "$max" ]] && [[ "$max" -gt 0 ]]; then
            laptop_brightness=$(( (cur * 100) / max ))
        fi
        break
    fi
done

# External monitor brightness: ddcci devices in /sys/class/backlight/
external_brightness=""
for dev in /sys/class/backlight/ddcci*; do
    [[ -d "$dev" ]] || continue
    devname=$(basename "$dev")
    cur=$(cat "$dev/brightness" 2>/dev/null)
    max=$(cat "$dev/max_brightness" 2>/dev/null)
    if [[ -n "$cur" ]] && [[ -n "$max" ]] && [[ "$max" -gt 0 ]]; then
        pct=$(( (cur * 100) / max ))
        external_brightness="${external_brightness}${devname}: ${pct}% "
    fi
done

if [[ -n "$external_brightness" ]]; then
    light_display="Light: eDP: ${laptop_brightness:-?}% ${external_brightness} |"
else
    light_display="Light: ${laptop_brightness:-?}%  |"
fi

# --- CPU Temperature ---
temp=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null)
if [[ -n "$temp" ]]; then
    temp_c=$(( temp / 1000 ))
    temp_display="Temp: ${temp_c}C"
else
    temp_display="Temp: ?"
fi

# --- RAM ---
MemTotal=$(awk '/^MemTotal/ {print $2}' /proc/meminfo)
MemAvailable=$(awk '/^MemAvailable/ {print $2}' /proc/meminfo)
MemPercentage=$(( (100 * (MemTotal - MemAvailable)) / MemTotal ))

# --- WiFi ---
connected_network=$(iwgetid -r 2>/dev/null)

# --- Assemble status line ---
sep=" | "
parts=""
[[ -n "$connected_network" ]] && parts="${parts}Net: ${connected_network}${sep}"
parts="${parts}${light_display}"
parts="${parts} Mic: ${mic_muted_display}${sep}"
parts="${parts}Out: ${volume_muted_display}${sep}"
parts="${parts}Vol: ${volume_percentage}%${sep}"
parts="${parts}${temp_display}${sep}"
parts="${parts}RAM: ${MemPercentage}%${sep}"
parts="${parts}BAT: ${battery_percentage}${sep}"
parts="${parts}${date_formatted}"

echo "$parts"
