#!/bin/bash

# Smart Volume Control Script
# Detects focused output and controls volume accordingly
# For external monitors, uses monitor's built-in speakers if available

set -euo pipefail

LOG_FILE="/tmp/smart-volume.log"
LOCK_FILE="/tmp/smart-volume.lock"
LOCK_TIMEOUT=2
CACHE_DIR="/tmp/smart-volume-cache"
CACHE_VALIDITY=2  # Cache valid for 2 seconds (volume changes frequently)

# Create lock to prevent concurrent executions
acquire_lock() {
    local count=0
    while [ $count -lt 20 ]; do  # Try for 2 seconds (20 * 0.1s)
        if mkdir "$LOCK_FILE" 2>/dev/null; then
            trap 'rm -rf "$LOCK_FILE"' EXIT
            return 0
        fi
        sleep 0.1
        count=$((count + 1))
    done
    echo "Another volume change in progress, skipping"
    exit 0
}

# Conditional logging - only when DEBUG=1
log() {
    if [ "${DEBUG:-0}" = "1" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
    fi
}

# Cache management functions
get_cache_file() {
    local key="$1"
    echo "$CACHE_DIR/${key}.cache"
}

get_cached_value() {
    local key="$1"
    local cache_file=$(get_cache_file "$key")
    
    if [ ! -f "$cache_file" ]; then
        log "Cache miss: No cache file for $key"
        return 1
    fi
    
    local cached_data=$(cat "$cache_file")
    local cached_timestamp=$(echo "$cached_data" | cut -d':' -f1)
    local cached_value=$(echo "$cached_data" | cut -d':' -f2)
    local current_timestamp=$(date +%s)
    local age=$((current_timestamp - cached_timestamp))
    
    # Check if cache is still valid
    if [ $age -le $CACHE_VALIDITY ]; then
        log "Cache hit: $key=$cached_value (age=${age}s)"
        echo "$cached_value"
        return 0
    else
        # Cache expired, remove it
        log "Cache expired: $key cache was ${age}s old (max ${CACHE_VALIDITY}s)"
        rm -f "$cache_file"
        return 1
    fi
}

set_cached_value() {
    local key="$1"
    local value="$2"
    local cache_file=$(get_cache_file "$key")
    local timestamp=$(date +%s)
    
    # Ensure cache directory exists
    mkdir -p "$CACHE_DIR"
    
    # Store timestamp:value
    echo "${timestamp}:${value}" > "$cache_file"
    log "Cache updated: $key=$value"
}

# Get currently focused output
get_focused_output() {
    swaymsg -t get_outputs | jq -r '.[] | select(.focused==true) | .name'
}

# Check if output is laptop display
is_laptop() {
    local output="$1"
    [[ "$output" == eDP-* ]]
}

# Get default audio sink
get_default_sink() {
    pactl get-default-sink 2>/dev/null
}

# Get current volume
get_volume() {
    local sink="${1:-@DEFAULT_SINK@}"
    pactl get-sink-volume "$sink" 2>/dev/null | grep -o '[0-9]*%' | head -1 | tr -d '%'
}

# Get mute status
is_muted() {
    local sink="${1:-@DEFAULT_SINK@}"
    pactl get-sink-mute "$sink" 2>/dev/null | grep -q 'yes'
}

# Control volume for laptop speakers/headphones
control_laptop_volume() {
    local action="$1"
    local step="${2:-5}"
    
    # Check cache first for boundaries
    local cache_key="laptop_volume"
    local cached_volume
    
    if cached_volume=$(get_cached_value "$cache_key"); then
        log "Using cached laptop volume: $cached_volume%"
        
        # Check boundaries with cached value
        case "$action" in
            up)
                if [ "$cached_volume" -ge 100 ]; then
                    log "Laptop volume already at maximum (100%), skipping"
                    return 0
                fi
                ;;
            down)
                if [ "$cached_volume" -eq 0 ]; then
                    log "Laptop volume already at minimum (0%), skipping"
                    return 0
                fi
                ;;
        esac
    fi
    
    # Get current volume
    local current=$(get_volume)
    log "Controlling laptop volume: $action by $step% (current: $current%)"
    
    # Apply volume change
    case "$action" in
        up)
            if [ "$current" -ge 100 ]; then
                log "Laptop volume already at maximum (100%), skipping"
                set_cached_value "$cache_key" "$current"
                return 0
            fi
            pactl set-sink-volume @DEFAULT_SINK@ "+${step}%"
            ;;
        down)
            if [ "$current" -eq 0 ]; then
                log "Laptop volume already at minimum (0%), skipping"
                set_cached_value "$cache_key" "$current"
                return 0
            fi
            pactl set-sink-volume @DEFAULT_SINK@ "-${step}%"
            ;;
        mute)
            pactl set-sink-mute @DEFAULT_SINK@ toggle
            if is_muted; then
                log "Laptop audio muted"
            else
                log "Laptop audio unmuted"
            fi
            return 0
            ;;
        set)
            local value="$step"
            pactl set-sink-volume @DEFAULT_SINK@ "${value}%"
            log "Laptop volume set to $value%"
            set_cached_value "$cache_key" "$value"
            return 0
            ;;
    esac
    
    # Get updated volume and cache it
    local new_volume=$(get_volume)
    set_cached_value "$cache_key" "$new_volume"
    log "Laptop volume now: $new_volume%"
}

# Control external monitor volume (if monitor has speakers)
control_external_volume() {
    local action="$1"
    local step="${2:-5}"
    local output="$3"
    
    # First check if monitor supports audio control via DDC/CI
    # VCP code 62 is audio volume, 8D is audio mute
    
    # Try to get cached bus number first
    local bus_cache_file="$CACHE_DIR/${output}.bus"
    local bus
    
    if [ -f "$bus_cache_file" ]; then
        local cached_data=$(cat "$bus_cache_file")
        local cached_timestamp=$(echo "$cached_data" | cut -d':' -f1)
        local cached_bus=$(echo "$cached_data" | cut -d':' -f2)
        local current_timestamp=$(date +%s)
        local age=$((current_timestamp - cached_timestamp))
        
        if [ $age -le 300 ]; then  # 5 minutes
            bus="$cached_bus"
            log "Using cached I2C bus $bus for $output"
        else
            rm -f "$bus_cache_file"
        fi
    fi
    
    if [ -z "${bus:-}" ]; then
        log "Detecting I2C bus for $output..."
        bus=$(ddcutil detect --enable-capabilities-cache 2>/dev/null | grep -B 2 "DRM_connector.*$output" | grep "I2C bus:" | head -1 | sed 's/.*\/dev\/i2c-\([0-9]*\).*/\1/')
        
        if [ -z "$bus" ]; then
            log "ERROR: Could not find I2C bus for $output"
            log "Falling back to laptop audio control"
            control_laptop_volume "$action" "$step"
            return
        fi
        
        # Cache the bus number
        mkdir -p "$CACHE_DIR"
        echo "$(date +%s):${bus}" > "$bus_cache_file"
        log "Bus cached: $output bus=$bus"
    fi
    
    # Check if monitor supports audio volume control
    local capabilities
    capabilities=$(ddcutil --bus "$bus" --enable-capabilities-cache capabilities 2>/dev/null | grep -E "Feature: 62|Feature: 8D" || true)
    
    if [ -z "$capabilities" ]; then
        log "Monitor $output does not support DDC audio control, using system audio"
        control_laptop_volume "$action" "$step"
        return
    fi
    
    # Check cache for current volume
    local cache_key="${output}_volume"
    local cached_volume
    
    if cached_volume=$(get_cached_value "$cache_key"); then
        log "Using cached external volume for $output: $cached_volume%"
        
        # Check boundaries with cached value
        case "$action" in
            up)
                if [ "$cached_volume" -ge 100 ]; then
                    log "External volume already at maximum (100%), skipping"
                    return 0
                fi
                ;;
            down)
                if [ "$cached_volume" -eq 0 ]; then
                    log "External volume already at minimum (0%), skipping"
                    return 0
                fi
                ;;
        esac
    fi
    
    # Get current volume from monitor
    local current
    current=$(ddcutil --bus "$bus" --enable-capabilities-cache getvcp 62 2>/dev/null | grep -o 'current value = *[0-9]*' | grep -o '[0-9]*' | head -1)
    
    if [ -z "$current" ]; then
        log "Could not get monitor volume, using system audio"
        control_laptop_volume "$action" "$step"
        return
    fi
    
    log "Controlling external monitor volume: $action by $step% for $output (current: $current%)"
    
    case "$action" in
        up)
            if [ "$current" -ge 100 ]; then
                log "External volume already at maximum (100%), skipping"
                set_cached_value "$cache_key" "$current"
                return 0
            fi
            local new=$((current + step))
            [ "$new" -gt 100 ] && new=100
            ;;
        down)
            if [ "$current" -eq 0 ]; then
                log "External volume already at minimum (0%), skipping"
                set_cached_value "$cache_key" "$current"
                return 0
            fi
            local new=$((current - step))
            [ "$new" -lt 0 ] && new=0
            ;;
        mute)
            # Toggle mute using VCP 8D
            local mute_status
            mute_status=$(ddcutil --bus "$bus" --enable-capabilities-cache getvcp 8D 2>/dev/null | grep -o 'current value = *[0-9]*' | grep -o '[0-9]*' | head -1)
            if [ "$mute_status" = "1" ]; then
                ddcutil --bus "$bus" --enable-capabilities-cache setvcp 8D 2 2>/dev/null
                log "External monitor unmuted"
            else
                ddcutil --bus "$bus" --enable-capabilities-cache setvcp 8D 1 2>/dev/null
                log "External monitor muted"
            fi
            return 0
            ;;
        set)
            local new="$step"
            ;;
        *)
            log "Unknown action: $action"
            return 1
            ;;
    esac
    
    log "Setting external monitor volume from $current% to $new%"
    
    # Set new volume
    if ddcutil --bus "$bus" --enable-capabilities-cache setvcp 62 "$new" 2>/dev/null; then
        log "External monitor volume set to $new%"
        set_cached_value "$cache_key" "$new"
    else
        log "Failed to set monitor volume, falling back to system audio"
        control_laptop_volume "$action" "$step"
    fi
}

# Set volume to specific value
set_volume() {
    local value="$1"
    
    # Acquire lock to prevent concurrent executions
    acquire_lock
    
    local output
    output=$(get_focused_output)
    log "Focused output: $output"
    
    # Validate value is between 0-100
    if [ "$value" -lt 0 ] || [ "$value" -gt 100 ]; then
        echo "Error: Volume value must be between 0-100"
        exit 1
    fi
    
    log "=== Setting volume to $value% ==="
    
    if is_laptop "$output"; then
        control_laptop_volume "set" "$value"
    else
        control_external_volume "set" "$value" "$output"
    fi
    
    log "=== Volume set completed ==="
}

# Main function
main() {
    local action="$1"
    local step="${2:-5}"
    
    # Acquire lock to prevent concurrent executions
    acquire_lock
    
    log "=== Smart Volume Control Started ==="
    log "Action: $action, Step: $step"
    
    # Get focused output
    local output
    output=$(get_focused_output)
    log "Focused output: $output"
    
    # Control volume based on output type
    if is_laptop "$output"; then
        control_laptop_volume "$action" "$step"
    else
        control_external_volume "$action" "$step" "$output"
    fi
    
    log "=== Volume control completed ==="
}

# Validate arguments
if [ $# -lt 1 ] || [ $# -gt 2 ]; then
    echo "Usage: $0 {up|down|mute|set} [step|value]"
    echo "  up/down: Adjust volume by step amount (default 5)"
    echo "  mute: Toggle mute"
    echo "  set: Set volume to specific value (0-100)"
    exit 1
fi

action="$1"

if [[ "$action" == "set" ]]; then
    if [ $# -ne 2 ]; then
        echo "Error: 'set' action requires a volume value (0-100)"
        exit 1
    fi
    value="$2"
    if ! [[ "$value" =~ ^[0-9]+$ ]] || [ "$value" -lt 0 ] || [ "$value" -gt 100 ]; then
        echo "Error: Volume value must be a number between 0-100"
        exit 1
    fi
elif [[ "$action" != "up" && "$action" != "down" && "$action" != "mute" ]]; then
    echo "Action must be 'up', 'down', 'mute', or 'set'"
    exit 1
fi

# Cleanup old cache files
cleanup_old_cache() {
    if [ -d "$CACHE_DIR" ]; then
        find "$CACHE_DIR" -name "*.cache" -type f -mmin +1 -delete 2>/dev/null || true
        find "$CACHE_DIR" -name "*.bus" -type f -mmin +10 -delete 2>/dev/null || true
    fi
}

# Run cleanup and appropriate function
cleanup_old_cache

if [[ "$action" == "set" ]]; then
    set_volume "$value"
else
    main "$@"
fi