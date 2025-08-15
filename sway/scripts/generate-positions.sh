#!/bin/bash

# Monitor Position Generator
# Automatically calculates display positions based on grid layout and monitor specifications
# Part of the modular Sway configuration system

set -euo pipefail

# Configuration paths
SWAY_CONFIG_DIR="/home/rs10/dotfiles/sway"
VARIABLES_DIR="$SWAY_CONFIG_DIR/config.d/variables.d"
DISPLAYS_CONF="$VARIABLES_DIR/03-displays.conf"
OUTPUT_FILE="$VARIABLES_DIR/04-monitor-positions.conf"

# Temporary files for parsing
TEMP_DIR="/tmp/sway-position-calc"
mkdir -p "$TEMP_DIR"

# Debug flag (set to 1 for verbose output)
DEBUG=${DEBUG:-0}

debug() {
    if [ "$DEBUG" -eq 1 ]; then
        echo "[DEBUG] $*" >&2
    fi
}

log() {
    echo "[INFO] $*" >&2
}

error() {
    echo "[ERROR] $*" >&2
    exit 1
}

# Extract variable from sway config
extract_variable() {
    local var_name="$1"
    local file="$2"
    grep "^set \$$var_name " "$file" | head -1 | sed "s/^set \$$var_name //g" | tr -d '"'
}

# Parse resolution string (e.g., "2880x1800@90.001Hz" -> width=2880, height=1800)
parse_resolution() {
    local res_string="$1"
    local width height
    
    width=$(echo "$res_string" | sed 's/@.*//' | cut -d'x' -f1)
    height=$(echo "$res_string" | sed 's/@.*//' | cut -d'x' -f2)
    
    echo "$width $height"
}

# Calculate effective dimensions (resolution / scale)
calculate_effective_dimensions() {
    local width="$1"
    local height="$2" 
    local scale="$3"
    
    # Handle decimal scales (like 1.8)
    local eff_width eff_height
    
    # Use bc for floating point arithmetic, fallback to integer division
    if command -v bc >/dev/null 2>&1; then
        eff_width=$(echo "scale=0; $width / $scale" | bc)
        eff_height=$(echo "scale=0; $height / $scale" | bc)
    else
        # Fallback for systems without bc
        # Convert scale to integer by multiplying by 10
        if [[ "$scale" == *.* ]]; then
            local scale_whole scale_decimal scale_factor
            scale_whole="${scale%.*}"
            scale_decimal="${scale#*.}"
            scale_factor=$((scale_whole * 10 + scale_decimal))
            eff_width=$(( (width * 10) / scale_factor ))
            eff_height=$(( (height * 10) / scale_factor ))
        else
            eff_width=$((width / scale))
            eff_height=$((height / scale))
        fi
    fi
    
    echo "$eff_width $eff_height"
}

# Load monitor specifications from config
load_monitor_specs() {
    local specs_file="$TEMP_DIR/monitor_specs"
    
    debug "Loading monitor specifications from $DISPLAYS_CONF"
    
    # Extract all monitor definitions
    for monitor in laptop external external2 external3 external4; do
        local res_var="${monitor}_res"
        local scale_var="${monitor}_scale"
        
        local resolution scale
        resolution=$(extract_variable "$res_var" "$DISPLAYS_CONF" || echo "")
        scale=$(extract_variable "$scale_var" "$DISPLAYS_CONF" || echo "1")
        
        if [ -n "$resolution" ]; then
            local width height eff_width eff_height
            read -r width height <<< "$(parse_resolution "$resolution")"
            read -r eff_width eff_height <<< "$(calculate_effective_dimensions "$width" "$height" "$scale")"
            
            echo "$monitor $width $height $scale $eff_width $eff_height" >> "$specs_file"
            debug "Monitor $monitor: ${width}x${height} @ scale $scale = effective ${eff_width}x${eff_height}"
        fi
    done
    
    echo "$specs_file"
}

# Parse active configuration
parse_active_config() {
    local config_string="$1"
    local layout_file="$TEMP_DIR/layout"
    
    debug "Parsing configuration: $config_string"
    
    # Remove quotes and parse "monitor:x,y monitor:x,y ..." format
    config_string=$(echo "$config_string" | tr -d '"')
    
    # Clear the layout file
    > "$layout_file"
    
    # Parse each monitor:position pair
    echo "$config_string" | tr ' ' '\n' | while IFS=':' read -r monitor coords; do
        if [ -n "$monitor" ] && [ -n "$coords" ]; then
            local x y
            IFS=',' read -r x y <<< "$coords"
            echo "$monitor $x $y" >> "$layout_file"
            debug "Layout: $monitor at grid position ($x,$y)"
        fi
    done
    
    # Wait for the subshell to complete and ensure file exists
    sleep 0.1
    [ -f "$layout_file" ] || touch "$layout_file"
    
    echo "$layout_file"
}

# Calculate grid dimensions and positions
calculate_positions() {
    local specs_file="$1"
    local layout_file="$2"
    local output_vars="$TEMP_DIR/position_vars"
    
    debug "Calculating monitor positions"
    
    # Find grid bounds
    local max_x=0 max_y=0
    while read -r monitor x y; do
        [ "$x" -gt "$max_x" ] && max_x="$x"
        [ "$y" -gt "$max_y" ] && max_y="$y"
    done < "$layout_file"
    
    debug "Grid dimensions: ${max_x}x${max_y}"
    
    # Calculate column widths and row heights
    declare -a col_widths row_heights
    for ((i=0; i<=max_x; i++)); do col_widths[i]=0; done
    for ((i=0; i<=max_y; i++)); do row_heights[i]=0; done
    
    # Find maximum width per column and height per row
    while read -r monitor x y; do
        if grep -q "^$monitor " "$specs_file"; then
            local eff_width eff_height
            eff_width=$(grep "^$monitor " "$specs_file" | awk '{print $5}')
            eff_height=$(grep "^$monitor " "$specs_file" | awk '{print $6}')
            
            [ "$eff_width" -gt "${col_widths[x]}" ] && col_widths[x]="$eff_width"
            [ "$eff_height" -gt "${row_heights[y]}" ] && row_heights[y]="$eff_height"
        fi
    done < "$layout_file"
    
    # Calculate cumulative offsets
    declare -a col_offsets row_offsets
    col_offsets[0]=0
    row_offsets[0]=0
    
    for ((i=1; i<=max_x; i++)); do
        col_offsets[i]=$((col_offsets[i-1] + col_widths[i-1]))
    done
    
    for ((i=1; i<=max_y; i++)); do
        row_offsets[i]=$((row_offsets[i-1] + row_heights[i-1]))
    done
    
    # Calculate final positions for each monitor
    while read -r monitor x y; do
        if grep -q "^$monitor " "$specs_file"; then
            local eff_width eff_height
            eff_width=$(grep "^$monitor " "$specs_file" | awk '{print $5}')
            eff_height=$(grep "^$monitor " "$specs_file" | awk '{print $6}')
            
            # Center monitor within its grid cell
            local cell_width="${col_widths[x]}"
            local cell_height="${row_heights[y]}"
            
            local pos_x pos_y
            pos_x=$((col_offsets[x] + (cell_width - eff_width) / 2))
            pos_y=$((row_offsets[y] + (cell_height - eff_height) / 2))
            
            echo "set \$${monitor}_pos ${pos_x},${pos_y}" >> "$output_vars"
            debug "Position for $monitor: ${pos_x},${pos_y} (centered in ${cell_width}x${cell_height} cell)"
        fi
    done < "$layout_file"
    
    echo "$output_vars"
}

# Generate the positions configuration file
generate_config_file() {
    local position_vars="$1"
    
    log "Generating monitor positions configuration: $OUTPUT_FILE"
    
    cat > "$OUTPUT_FILE" << 'EOF'
### Monitor Positions Configuration
# Auto-generated by scripts/generate-positions.sh
# DO NOT EDIT MANUALLY - This file is regenerated when monitor configuration changes
#
# To modify monitor layout:
# 1. Edit config.d/variables.d/03-displays.conf
# 2. Change $active_monitor_config to desired configuration
# 3. Reload Sway configuration (Super+Shift+C)

EOF
    
    # Add timestamp
    echo "# Generated on: $(date)" >> "$OUTPUT_FILE"
    echo "# Active configuration: $(extract_variable "active_monitor_config" "$DISPLAYS_CONF")" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    
    # Add position variables
    if [ -f "$position_vars" ]; then
        cat "$position_vars" >> "$OUTPUT_FILE"
    else
        echo "# No positions calculated - check configuration" >> "$OUTPUT_FILE"
    fi
    
    # Add fallback positions for undefined monitors
    echo "" >> "$OUTPUT_FILE"
    echo "# Fallback positions for undefined monitors" >> "$OUTPUT_FILE"
    for monitor in laptop external external2 external3 external4; do
        if ! grep -q "set \$${monitor}_pos" "$OUTPUT_FILE" 2>/dev/null; then
            echo "set \$${monitor}_pos 0,0" >> "$OUTPUT_FILE"
        fi
    done
}

# Main execution
main() {
    log "Starting monitor position calculation"
    
    # Check if displays config exists
    [ -f "$DISPLAYS_CONF" ] || error "Displays configuration not found: $DISPLAYS_CONF"
    
    # Extract active configuration
    local active_config config_var_name actual_config
    active_config=$(extract_variable "active_monitor_config" "$DISPLAYS_CONF")
    [ -n "$active_config" ] || error "No active monitor configuration found"
    
    # If it's a variable reference (starts with $), resolve it
    if [[ "$active_config" == \$* ]]; then
        config_var_name="${active_config#\$}"
        actual_config=$(extract_variable "$config_var_name" "$DISPLAYS_CONF")
        [ -n "$actual_config" ] || error "Configuration variable $config_var_name not found"
    else
        actual_config="$active_config"
    fi
    
    log "Active configuration: $active_config -> $actual_config"
    
    # Load monitor specifications
    local specs_file
    specs_file=$(load_monitor_specs)
    
    # Parse layout configuration  
    local layout_file
    layout_file=$(parse_active_config "$actual_config")
    
    # Calculate positions
    local position_vars
    position_vars=$(calculate_positions "$specs_file" "$layout_file")
    
    # Generate output file
    generate_config_file "$position_vars"
    
    log "Monitor position calculation completed successfully"
    
    # Cleanup
    rm -rf "$TEMP_DIR"
}

# Run main function
main "$@"