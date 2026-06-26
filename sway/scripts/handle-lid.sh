#!/usr/bin/env bash
#
# handle-lid.sh — keep Sway's layout in sync with the laptop lid.
#
# logind may ignore lid events when docked (HandleLidSwitchDocked=ignore), but
# the internal panel often stays DRM-"connected". Sway only reacts to output
# enable/disable, so we disable eDP when the lid is closed with an external
# monitor present, and re-enable it when the lid opens.
#
# Started by the user unit sway-lid.service (see dotfiles/systemd/user/).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPLY_MONITORS="${APPLY_MONITORS:-$SCRIPT_DIR/apply-monitors.sh}"
LAPTOP_OUTPUT="${LAPTOP_OUTPUT:-eDP-1}"
POLL_INTERVAL="${POLL_INTERVAL:-0.5}"

log() { echo "[handle-lid] $*" >&2; }

# shellcheck source=sway-ipc.sh
source "$SCRIPT_DIR/sway-ipc.sh"

wait_for_sway() {
    local i
    for (( i = 1; i <= 60; i++ )); do
        if ensure_sway; then
            return 0
        fi
        sleep 1
    done

    log "Sway IPC not available"
    return 1
}

lid_closed() {
    busctl get-property org.freedesktop.login1 /org/freedesktop/login1 \
        org.freedesktop.login1.Manager LidClosed 2>/dev/null \
        | awk '{print $2}'
}

external_connected() {
    local entry name status
    for entry in /sys/class/drm/card*-*/status; do
        [[ -e "$entry" ]] || continue
        name=$(basename "$(dirname "$entry")")
        [[ "$name" == *eDP* ]] && continue
        status=$(<"$entry")
        if [[ "$status" == connected ]]; then
            return 0
        fi
    done
    return 1
}

apply_lid_state() {
    local closed=$1

    if [[ "$closed" == "true" ]]; then
        if external_connected; then
            log "lid closed with external display — disabling $LAPTOP_OUTPUT"
            swaymsg output "$LAPTOP_OUTPUT" disable >/dev/null
            "$APPLY_MONITORS"
        else
            log "lid closed, no external display — leaving $LAPTOP_OUTPUT alone"
        fi
        return 0
    fi

    log "lid open — enabling $LAPTOP_OUTPUT"
    swaymsg output "$LAPTOP_OUTPUT" enable >/dev/null
    "$APPLY_MONITORS"
}

main() {
    wait_for_sway

    local current last=""
    while true; do
        current=$(lid_closed)
        if [[ "$current" != "$last" ]]; then
            apply_lid_state "$current"
            last=$current
        fi
        sleep "$POLL_INTERVAL"
    done
}

main "$@"
