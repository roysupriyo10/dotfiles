#!/usr/bin/env bash
# Turn laptop/external panels off while keeping the system fully awake (OLED-safe).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=sway-ipc.sh
source "$SCRIPT_DIR/sway-ipc.sh"

APPLY_MONITORS="${APPLY_MONITORS:-$SCRIPT_DIR/apply-monitors.sh}"

usage() {
    cat <<'EOF'
Usage: display-power.sh <on|off|toggle|status> [--recover]

  on         Power displays on
  off        Power displays off (system stays awake)
  toggle     Flip current state
  status     Print on, off, or unknown
  --recover  Retry enable/mode/power (for after-resume / stuck outputs)

Works over SSH; finds the graphical session's Sway socket automatically.
EOF
}

any_active() {
    swaymsg -t get_outputs | jq -e '[.[] | select(.active == true)] | length > 0' >/dev/null
}

display_power_status() {
    ensure_sway
    # Prefer .power over .dpms: after a failed resume every output can be
    # inactive with power=false, which should count as off (so toggle turns on).
    swaymsg -t get_outputs | jq -r '
        if length == 0 then "unknown"
        elif any(.power == true) then "on"
        else "off"
        end'
}

recover_outputs() {
    local attempt
    ensure_sway

    for attempt in 1 2 3 4 5 6 7 8; do
        swaymsg "output * enable" >/dev/null 2>&1 || true
        swaymsg "output * power on" >/dev/null 2>&1 || true
        if [[ -x "$APPLY_MONITORS" ]]; then
            "$APPLY_MONITORS" >/dev/null 2>&1 || true
        fi
        swaymsg "output * power on" >/dev/null 2>&1 || true

        if any_active; then
            echo "display power on (recovered, attempt ${attempt})"
            return 0
        fi
        sleep 1
    done

    echo "display power: no active outputs after recover" >&2
    return 1
}

set_display_power() {
    local state=$1
    local recover=${2:-0}

    ensure_sway

    # Give DRM/nvidia-resume a moment after system wake before touching outputs.
    if [[ "$recover" == "1" && "$state" == "on" ]]; then
        sleep 2
    fi

    if [[ "$state" == "off" ]]; then
        swaymsg "output * power off" >/dev/null
        echo "display power off"
        return 0
    fi

    swaymsg "output * power on" >/dev/null

    if any_active; then
        echo "display power on"
        return 0
    fi

    # power on reported success but nothing is active (common post-suspend).
    recover_outputs
}

main() {
    local cmd="" recover=0 arg

    for arg in "$@"; do
        case "$arg" in
            --recover) recover=1 ;;
            on|off|toggle|status|-h|--help|help) cmd=$arg ;;
            *)
                usage >&2
                exit 1
                ;;
        esac
    done

    case "${cmd:-}" in
        on)
            set_display_power on "$recover"
            ;;
        off)
            set_display_power off
            ;;
        toggle)
            case "$(display_power_status)" in
                on) set_display_power off ;;
                *) set_display_power on 1 ;;
            esac
            ;;
        status)
            display_power_status
            ;;
        -h|--help|help)
            usage
            ;;
        *)
            usage >&2
            exit 1
            ;;
    esac
}

main "$@"
