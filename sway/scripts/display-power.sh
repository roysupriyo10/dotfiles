#!/usr/bin/env bash
# Turn laptop/external panels off while keeping the system fully awake (OLED-safe).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=sway-ipc.sh
source "$SCRIPT_DIR/sway-ipc.sh"

usage() {
    cat <<'EOF'
Usage: display-power.sh <on|off|toggle|status>

  on      Power displays on
  off     Power displays off (system stays awake)
  toggle  Flip current state
  status  Print on, off, or unknown

Works over SSH; finds the graphical session's Sway socket automatically.
EOF
}

display_power_status() {
    ensure_sway
    swaymsg -t get_outputs | jq -r '
        [.[] | select(.active) | .dpms] as $states
        | if ($states | length) == 0 then "unknown"
          elif ($states | all) then "on"
          else "off"
          end'
}

set_display_power() {
    local state=$1
    ensure_sway
    swaymsg "output * power $state" >/dev/null
    echo "display power $state"
}

main() {
    case "${1:-}" in
        on|off)
            set_display_power "$1"
            ;;
        toggle)
            case "$(display_power_status)" in
                on) set_display_power off ;;
                *) set_display_power on ;;
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
