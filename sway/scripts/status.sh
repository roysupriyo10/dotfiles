date_formatted=$(date +"%Y-%m-%d %A %I:%M:%S %p")

battery_status=$(cat /sys/class/power_supply/BAT1/status)

volume_muted=$(pamixer --get-mute)

mic_muted=$(pamixer --source 59 --get-mute)

volume_percentage=$(pamixer --get-volume)

battery_percentage=$(cat /sys/class/power_supply/BAT1/capacity)%

[[ $battery_status = "Charging" ]] && battery_percentage="${battery_percentage}+"
[[ $volume_muted = true ]] && volume_muted_display="Muted" || volume_muted_display="Unmuted"
[[ $mic_muted = true ]] && mic_muted_display="Muted" || mic_muted_display="Unmuted"

# Get brightness for laptop display (eDP-1)
maximum_brightness=$(brightnessctl m | awk '{print $1}')
current_brightness=$(brightnessctl g | awk '{print $1}')
laptop_percentage=$(( ($current_brightness * 100) / $maximum_brightness ))

# Get brightness for external monitors via DDC
external_brightness=""
for output in $(swaymsg -t get_outputs | jq -r '.[] | select(.name | startswith("eDP") | not) | .name'); do
    # Try to find the I2C bus for this output
    bus=$(ddcutil detect --enable-capabilities-cache 2>/dev/null | grep -B 2 "DRM_connector.*$output" | grep "I2C bus:" | head -1 | sed 's/.*\/dev\/i2c-\([0-9]*\).*/\1/')
    
    if [ -n "$bus" ]; then
        # Get current brightness from DDC
        brightness=$(ddcutil --bus "$bus" --enable-capabilities-cache getvcp 10 2>/dev/null | grep -o 'current value = *[0-9]*' | grep -o '[0-9]*' | head -1)
        if [ -n "$brightness" ]; then
            external_brightness="${external_brightness}${output}: ${brightness}% "
        fi
    fi
done

custom_space=$('')

MemTotal=$(grep -E '^MemTotal' /proc/meminfo | awk '{print $2}')
MemAvailable=$(grep -E '^MemAvailable' /proc/meminfo | awk '{print $2}')

MemPercentage=$(( (100 * ($MemTotal - $MemAvailable)) / $MemTotal ))

temp=$(sensors | grep "Package id 0" | awk '{print $4}')

connected_network=$(iwgetid -r)

# Display brightness for all monitors
if [ -n "$external_brightness" ]; then
    light_display="Light: eDP-1: ${laptop_percentage}% ${external_brightness}${custom_space} |"
else
    light_display="Light: ${laptop_percentage}% ${custom_space} |"
fi
mic_display="${custom_space} Mic: ${mic_muted_display} ${custom_space} |"
network_display="${custom_space} Network: ${connected_network} ${custom_space} |"
out_display="${custom_space} Out: ${volume_muted_display} ${custom_space} |"
volume_display="${custom_space} Vol: ${volume_percentage}% ${custom_space} |"
temperature_display="${custom_space} Temp: ${temp} ${custom_space} |"
ram_display="${custom_space} RAM: ${MemPercentage}% ${custom_space} |"
battery_display="${custom_space} BAT: ${battery_percentage} ${custom_space} |"
date_display="${custom_space} ${date_formatted}"

# private_display="${custom_space} Private IP - ${private_ip} ${custom_space} |"
# light_display="${custom_space} Light - ${current_percentage}% (${current_brightness} of ${maximum_brightness}) ${custom_space} |"
# mic_display="${custom_space} Mic - ${mic_muted_display} ${custom_space} |"
# out_display="${custom_space} Out - ${volume_muted_display} ${custom_space} |"
# volume_display="${custom_space} Volume - ${volume_percentage}% ${custom_space} |"
# battery_display="${custom_space} BAT: ${battery_percentage} - ${battery_status} ${custom_space} |"
# date_display="${custom_space} ${date_formatted}"

echo "${network_display} ${private_display} ${light_display} ${mic_display} ${out_display} ${volume_display} ${temperature_display} ${ram_display} ${battery_display} ${date_display}"


# echo "Private IP - ${private_ip} ${custom_space} | Light - ${current_percentage}% (${current_brightness} of ${maximum_brightness}) ${custom_space} | ${custom_space} Mic - ${mic_muted_display} ${custom_space} | ${custom_space} Out - ${volume_muted_display} ${custom_space} | ${custom_space} Volume - ${volume_percentage}% ${custom_space} | ${custom_space} ${battery_percentage} - ${battery_status} ${custom_space} | ${custom_space} ${date_formatted}"
# echo "Light - ${current_percentage}% (${current_brightness} of ${maximum_brightness}) | ${volume_muted_display} | Vol ${volume_percentage}% | ${battery_percentage} - ${battery_status} | ${date_formatted}"
