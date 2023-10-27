date_formatted=$(date +"%Y-%m-%d %A %I:%M:%S %p")

battery_status=$(cat /sys/class/power_supply/BAT1/status)

volume_percentage=$(pamixer --get-volume)

battery_percentage=$(cat /sys/class/power_supply/BAT1/capacity)%

maximum_brightness=$(brightnessctl m)

current_brightness=$(brightnessctl g)

current_percentage=$($current_brightness / $maximum_brightness * 100)

custom_space=$('    ')

echo "${current_brightness} / ${maximum_brightness} ${custom_space} | ${custom_space} Vol ${volume_percentage}% ${custom_space} | ${custom_space} ${battery_percentage} ${custom_space} | ${custom_space} ${battery_status} ${custom_space} | ${custom_space} ${date_formatted}"
