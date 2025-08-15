#!/bin/bash

# Smart Brightness Control Script
# Uses swaymsg to detect focused output and controls brightness accordingly

set -euo pipefail

LOG_FILE="/tmp/smart-brightness.log"
LOCK_FILE="/tmp/smart-brightness.lock"
LOCK_TIMEOUT=2
CACHE_DIR="/tmp/smart-brightness-cache"
CACHE_VALIDITY=5  # Cache valid for 5 seconds
BUS_CACHE_VALIDITY=300  # Bus cache valid for 5 minutes

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
    echo "Another brightness change in progress, skipping"
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
    local output="$1"
    echo "$CACHE_DIR/${output}.cache"
}

get_cached_brightness() {
    local output="$1"
    local cache_file=$(get_cache_file "$output")
    
    if [ ! -f "$cache_file" ]; then
        log "Cache miss: No cache file for $output"
        return 1
    fi
    
    local cached_data=$(cat "$cache_file")
    local cached_timestamp=$(echo "$cached_data" | cut -d':' -f1)
    local cached_brightness=$(echo "$cached_data" | cut -d':' -f2)
    local current_timestamp=$(date +%s)
    local age=$((current_timestamp - cached_timestamp))
    
    # Check if cache is still valid (within 5 seconds)
    if [ $age -le $CACHE_VALIDITY ]; then
        log "Cache hit: $output brightness=$cached_brightness% (age=${age}s)"
        echo "$cached_brightness"
        return 0
    else
        # Cache expired, remove it
        log "Cache expired: $output brightness cache was ${age}s old (max ${CACHE_VALIDITY}s)"
        rm -f "$cache_file"
        return 1
    fi
}

set_cached_brightness() {
    local output="$1"
    local brightness="$2"
    local cache_file=$(get_cache_file "$output")
    local timestamp=$(date +%s)
    
    # Ensure cache directory exists
    mkdir -p "$CACHE_DIR"
    
    # Store timestamp:brightness
    echo "${timestamp}:${brightness}" > "$cache_file"
    log "Cache updated: $output brightness=$brightness%"
}

invalidate_cache() {
    local output="$1"
    local cache_file=$(get_cache_file "$output")
    rm -f "$cache_file"
}

# Bus number caching functions
get_bus_cache_file() {
    local output="$1"
    echo "$CACHE_DIR/${output}.bus"
}

get_cached_bus() {
    local output="$1"
    local bus_cache_file=$(get_bus_cache_file "$output")
    
    if [ ! -f "$bus_cache_file" ]; then
        log "Bus cache miss: No bus cache file for $output"
        return 1
    fi
    
    local cached_data=$(cat "$bus_cache_file")
    local cached_timestamp=$(echo "$cached_data" | cut -d':' -f1)
    local cached_bus=$(echo "$cached_data" | cut -d':' -f2)
    local current_timestamp=$(date +%s)
    local age=$((current_timestamp - cached_timestamp))
    
    # Check if bus cache is still valid (within 5 minutes)
    if [ $age -le $BUS_CACHE_VALIDITY ]; then
        log "Bus cache hit: $output bus=$cached_bus (age=${age}s)"
        echo "$cached_bus"
        return 0
    else
        # Bus cache expired, remove it
        log "Bus cache expired: $output bus cache was ${age}s old (max ${BUS_CACHE_VALIDITY}s)"
        rm -f "$bus_cache_file"
        return 1
    fi
}

set_cached_bus() {
    local output="$1"
    local bus="$2"
    local bus_cache_file=$(get_bus_cache_file "$output")
    local timestamp=$(date +%s)
    
    # Ensure cache directory exists
    mkdir -p "$CACHE_DIR"
    
    # Store timestamp:bus
    echo "${timestamp}:${bus}" > "$bus_cache_file"
    log "Bus cache updated: $output bus=$bus"
}

# Get currently focused output
get_focused_output() {
    swaymsg -t get_outputs | jq -r '.[] | select(.focused==true) | .name'
}

# Check if output is laptop display (starts with eDP)
is_laptop() {
    local output="$1"
    [[ "$output" == eDP-* ]]
}

# Control laptop brightness using brightnessctl
control_laptop_brightness() {
    local action="$1"
    local step="$2"
    local output="eDP-1"  # Laptop display identifier
    
    # Try to get cached brightness first
    local cached_brightness
    if cached_brightness=$(get_cached_brightness "$output"); then
        log "Using cached laptop brightness: $cached_brightness%"
        
        # Check boundaries with cached value
        case "$action" in
            up)
                if [ "$cached_brightness" -ge 100 ]; then
                    log "Laptop brightness already at maximum (100%), skipping"
                    return 0
                fi
                ;;
            down)
                if [ "$cached_brightness" -eq 0 ]; then
                    log "Laptop brightness already at minimum (0%), skipping"
                    return 0
                fi
                ;;
        esac
    fi
    
    # Get current brightness percentage (either cache miss or boundary check passed)
    local current=$(brightnessctl g)
    local max=$(brightnessctl m)
    local percent=$(( (current * 100) / max ))
    
    log "Controlling laptop brightness: $action by $step% (current: $percent%)"
    
    # Final boundary check with actual values
    case "$action" in
        up)
            if [ "$percent" -ge 100 ]; then
                log "Laptop brightness already at maximum (100%), skipping"
                set_cached_brightness "$output" "$percent"
                return 0
            fi
            brightnessctl s "${step}%+"
            ;;
        down)
            if [ "$percent" -eq 0 ]; then
                log "Laptop brightness already at minimum (0%), skipping"
                set_cached_brightness "$output" "$percent"
                return 0
            fi
            brightnessctl s "${step}%-"
            ;;
    esac
    
    # Get updated brightness and cache it
    current=$(brightnessctl g)
    max=$(brightnessctl m)
    percent=$(( (current * 100) / max ))
    set_cached_brightness "$output" "$percent"
    log "Laptop brightness now: $percent%"
}

# Control external monitor brightness using ddcutil
control_external_brightness() {
    local action="$1"
    local step="$2"
    local output="$3"
    
    # Try to get cached brightness first
    local cached_brightness
    if cached_brightness=$(get_cached_brightness "$output"); then
        log "Using cached external brightness for $output: $cached_brightness%"
        
        # Check boundaries with cached value
        case "$action" in
            up)
                if [ "$cached_brightness" -ge 100 ]; then
                    log "External monitor brightness already at maximum (100%), skipping"
                    return 0
                fi
                ;;
            down)
                if [ "$cached_brightness" -eq 0 ]; then
                    log "External monitor brightness already at minimum (0%), skipping"
                    return 0
                fi
                ;;
        esac
    fi
    
    # Cache miss or boundary check passed - proceed with DDC operations
    # Try to get cached bus number first
    local bus
    if bus=$(get_cached_bus "$output"); then
        log "Using cached I2C bus $bus for $output"
    else
        # Bus cache miss - detect and cache the bus number
        log "Detecting I2C bus for $output..."
        bus=$(ddcutil detect --enable-capabilities-cache 2>/dev/null | grep -B 2 "DRM_connector.*$output" | grep "I2C bus:" | head -1 | sed 's/.*\/dev\/i2c-\([0-9]*\).*/\1/')
        
        if [ -z "$bus" ]; then
            log "ERROR: Could not find I2C bus for $output"
            return 1
        fi
        
        # Cache the bus number for future use
        set_cached_bus "$output" "$bus"
        log "Using detected I2C bus $bus for $output"
    fi
    
    # Get current brightness
    local current
    current=$(ddcutil --bus "$bus" --enable-capabilities-cache getvcp 10 2>/dev/null | grep -o 'current value = *[0-9]*' | grep -o '[0-9]*' | head -1)
    
    if [ -z "$current" ]; then
        log "ERROR: Could not get current brightness"
        return 1
    fi
    
    log "Controlling external monitor brightness: $action by $step% for $output (current: $current%)"
    
    # Final boundary check with actual values
    case "$action" in
        up)
            if [ "$current" -ge 100 ]; then
                log "External monitor brightness already at maximum (100%), skipping"
                set_cached_brightness "$output" "$current"
                return 0
            fi
            ;;
        down)
            if [ "$current" -eq 0 ]; then
                log "External monitor brightness already at minimum (0%), skipping"
                set_cached_brightness "$output" "$current"
                return 0
            fi
            ;;
    esac
    
    # Calculate new brightness
    local new
    case "$action" in
        up)
            new=$((current + step))
            [ "$new" -gt 100 ] && new=100
            ;;
        down)
            new=$((current - step))
            [ "$new" -lt 0 ] && new=0
            ;;
    esac
    
    log "Changing brightness from $current% to $new%"
    
    # Set new brightness
    if ddcutil --bus "$bus" --enable-capabilities-cache setvcp 10 "$new" 2>/dev/null; then
        log "External monitor brightness set to $new%"
        # Cache the new brightness value
        set_cached_brightness "$output" "$new"
    else
        log "ERROR: Failed to set external monitor brightness"
        return 1
    fi
}

# Set brightness to specific value
set_brightness() {
    local value="$1"
    
    # Acquire lock to prevent concurrent executions
    acquire_lock
    
    local output
    output=$(get_focused_output)
    log "Focused output: $output"
    
    # Validate value is between 0-100
    if [ "$value" -lt 0 ] || [ "$value" -gt 100 ]; then
        echo "Error: Brightness value must be between 0-100"
        exit 1
    fi
    
    log "=== Setting brightness to $value% ==="
    
    if is_laptop "$output"; then
        log "Setting laptop brightness to $value%"
        brightnessctl s "$value%"
        # Cache the new value
        set_cached_brightness "eDP-1" "$value"
        log "Laptop brightness set to $value%"
    else
        # Try to get cached bus number first
        local bus
        if bus=$(get_cached_bus "$output"); then
            log "Using cached I2C bus $bus for $output"
        else
            # Bus cache miss - detect and cache the bus number
            log "Detecting I2C bus for $output..."
            bus=$(ddcutil detect --enable-capabilities-cache 2>/dev/null | grep -B 2 "DRM_connector.*$output" | grep "I2C bus:" | head -1 | sed 's/.*\/dev\/i2c-\([0-9]*\).*/\1/')
            
            if [ -z "$bus" ]; then
                log "ERROR: Could not find I2C bus for $output"
                return 1
            fi
            
            # Cache the bus number for future use
            set_cached_bus "$output" "$bus"
            log "Using detected I2C bus $bus for $output"
        fi
        
        log "Setting external monitor brightness to $value%"
        
        if ddcutil --bus "$bus" --enable-capabilities-cache setvcp 10 "$value" 2>/dev/null; then
            # Cache the new value
            set_cached_brightness "$output" "$value"
            log "External monitor brightness set to $value%"
        else
            log "ERROR: Failed to set external monitor brightness"
            return 1
        fi
    fi
    
    log "=== Brightness set completed ==="
}

# Main function
main() {
    local action="$1"
    local step="${2:-10}"
    
    # Acquire lock to prevent concurrent executions
    acquire_lock
    
    log "=== Smart Brightness Control Started ==="
    log "Action: $action, Step: $step"
    
    # Get focused output
    local output
    output=$(get_focused_output)
    log "Focused output: $output"
    
    # Control brightness based on output type
    if is_laptop "$output"; then
        control_laptop_brightness "$action" "$step"
    else
        control_external_brightness "$action" "$step" "$output"
    fi
    
    log "=== Brightness control completed ==="
}

# Validate arguments
if [ $# -lt 1 ] || [ $# -gt 2 ]; then
    echo "Usage: $0 {up|down|set} [step|value]"
    echo "  up/down: Adjust brightness by step amount (default 10)"
    echo "  set: Set brightness to specific value (0-100)"
    exit 1
fi

action="$1"

if [[ "$action" == "set" ]]; then
    if [ $# -ne 2 ]; then
        echo "Error: 'set' action requires a brightness value (0-100)"
        exit 1
    fi
    value="$2"
    if ! [[ "$value" =~ ^[0-9]+$ ]] || [ "$value" -lt 0 ] || [ "$value" -gt 100 ]; then
        echo "Error: Brightness value must be a number between 0-100"
        exit 1
    fi
elif [[ "$action" != "up" && "$action" != "down" ]]; then
    echo "Action must be 'up', 'down', or 'set'"
    exit 1
fi

# Cleanup old cache files (older than 1 minute)
cleanup_old_cache() {
    if [ -d "$CACHE_DIR" ]; then
        find "$CACHE_DIR" -name "*.cache" -type f -mmin +1 -delete 2>/dev/null || true
        find "$CACHE_DIR" -name "*.bus" -type f -mmin +10 -delete 2>/dev/null || true
    fi
}

# Run cleanup and appropriate function
cleanup_old_cache

if [[ "$action" == "set" ]]; then
    set_brightness "$value"
else
    main "$@"
fi