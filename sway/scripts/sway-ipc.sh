#!/usr/bin/env bash
# Shared Sway IPC helpers. Works from SSH without SWAYSOCK in the environment.

ensure_sway() {
    if [[ -n "${SWAYSOCK:-}" ]] && [[ -S "$SWAYSOCK" ]] \
        && swaymsg -t get_version >/dev/null 2>&1; then
        return 0
    fi

    local uid dir sock
    uid=$(id -u)
    dir="${XDG_RUNTIME_DIR:-/run/user/$uid}"

    if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
        SWAYSOCK="$dir/sway-ipc.$WAYLAND_DISPLAY.sock"
        export SWAYSOCK
        if [[ -S "$SWAYSOCK" ]] && swaymsg -t get_version >/dev/null 2>&1; then
            return 0
        fi
    fi

    for sock in "$dir"/sway-ipc.*.sock; do
        [[ -S "$sock" ]] || continue
        SWAYSOCK=$sock
        export SWAYSOCK
        if swaymsg -t get_version >/dev/null 2>&1; then
            return 0
        fi
    done

    echo "sway-ipc: no Sway socket under $dir (is the graphical session running?)" >&2
    return 1
}
