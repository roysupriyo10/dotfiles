date_formatted=$(date +"%Y-%m-%d %A %I:%M:%S %p")

battery_status=$(cat /sys/class/power_supply/BAT1/status)

volume_muted=$(pamixer --get-mute)

mic_muted=$(pamixer --source 1 --get-mute)

volume_percentage=$(pamixer --get-volume)

battery_percentage=$(cat /sys/class/power_supply/BAT1/capacity)%

[[ $volume_muted = true ]] && volume_muted_display="Muted" || volume_muted_display="Unmuted"
[[ $mic_muted = true ]] && mic_muted_display="Muted" || mic_muted_display="Unmuted"

maximum_brightness=$(brightnessctl m | awk '{print $1}')

current_brightness=$(brightnessctl g | awk '{print $1}')

current_percentage=$(( ($current_brightness * 100) / $maximum_brightness ))

custom_space=$('')

echo "Light - ${current_percentage}% (${current_brightness} of ${maximum_brightness}) ${custom_space} | ${custom_space} Mic - ${mic_muted_display} ${custom_space} | ${custom_space} Out - ${volume_muted_display} ${custom_space} | ${custom_space} Volume - ${volume_percentage}% ${custom_space} | ${custom_space} ${battery_percentage} - ${battery_status} ${custom_space} | ${custom_space} ${date_formatted}"
# echo "Light - ${current_percentage}% (${current_brightness} of ${maximum_brightness}) | ${volume_muted_display} | Vol ${volume_percentage}% | ${battery_percentage} - ${battery_status} | ${date_formatted}"
