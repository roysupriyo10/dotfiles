date_formatted=$(date +"%Y-%m-%d %A %I:%M:%S %p")

battery_status=$(cat /sys/class/power_supply/BAT1/status)

volume_muted=$(pamixer --get-mute)

mic_muted=$(pamixer --source 59 --get-mute)

volume_percentage=$(pamixer --get-volume)

battery_percentage=$(cat /sys/class/power_supply/BAT1/capacity)%

[[ $battery_status = "Charging" ]] && battery_percentage="${battery_percentage}+"
[[ $volume_muted = true ]] && volume_muted_display="Muted" || volume_muted_display="Unmuted"
[[ $mic_muted = true ]] && mic_muted_display="Muted" || mic_muted_display="Unmuted"

private_ip=$(ip route get 1| head -1 | cut -d' ' -f7)

maximum_brightness=$(brightnessctl m | awk '{print $1}')

current_brightness=$(brightnessctl g | awk '{print $1}')

current_percentage=$(( ($current_brightness * 100) / $maximum_brightness ))

custom_space=$('')

MemTotal=$(grep -E '^MemTotal' /proc/meminfo | awk '{print $2}')
MemAvailable=$(grep -E '^MemAvailable' /proc/meminfo | awk '{print $2}')

MemPercentage=$(( (100 * ($MemTotal - $MemAvailable)) / $MemTotal ))

temp=$(sensors | grep "Package id 0" | awk '{print $4}')

connected_network=$(iwgetid -r)

private_display="${custom_space} PIP: ${private_ip} ${custom_space} |"
light_display="${custom_space} Light: ${current_percentage}% ${custom_space} |"
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
