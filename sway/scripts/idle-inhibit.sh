#!/usr/bin/env bash
# Hold the system awake using Sway's built-in per-window inhibit_idle.
#
# Sway is the only thing swayidle listens to: while any container has an idle
# inhibitor set, Sway stops reporting idle and swayidle's timers reset. This
# script drives that inhibitor over IPC only — it never spawns or terminates a
# process.
#
# Holders are refcounted so concurrent users (two agents, an agent plus a
# manual toggle) don't cancel each other. Each holder is a file under
# $STATE_DIR/<con_id>/<pid>, validated against /proc so a holder that dies
# without releasing is reaped instead of pinning the machine awake forever.
#
# Linux/Sway only — sway/ is LINUX-only in the install manifest. On macOS,
# keep-awake uses caffeinate instead.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=sway-ipc.sh
source "$SCRIPT_DIR/sway-ipc.sh"

STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/sway-idle-inhibit"
LOCK="$STATE_DIR/.lock"

usage() {
    cat <<'EOF'
Usage: idle-inhibit.sh <command> [options]

  acquire   Hold the system awake on behalf of a process
  release   Drop a previously acquired hold
  toggle    Flip a manual hold on the focused window
  status    Print a short indicator (empty when nothing is holding)
  list      Show every active holder
  reap      Drop holders whose process or window is gone

Options:
  --pid <pid>      Owning process (default: parent of this script)
  --label <text>   Name shown in status/list (default: the owner's comm)
  --con <con_id>   Target container (default: the one owning --pid)

Holds are refcounted and released automatically when the owning process
exits, so `keep-awake <cmd>` is the normal way to use this.
EOF
}

# --- state -------------------------------------------------------------------

lock() {
    mkdir -p "$STATE_DIR"
    exec 9>"$LOCK"
    flock 9
}

# Second field of /proc/<pid>/stat can contain spaces and parens, so cut past
# the final ')' before counting fields. starttime is field 22 overall, which is
# token 20 of what remains.
proc_starttime() {
    local pid=$1 rest
    [[ -r "/proc/$pid/stat" ]] || return 1
    rest=$(</proc/"$pid"/stat)
    rest=${rest#*') '}
    awk '{print $20}' <<<"$rest"
}

proc_comm() {
    local pid=$1
    [[ -r "/proc/$pid/comm" ]] && tr -d '\n' < "/proc/$pid/comm" || printf 'unknown'
}

proc_ppid() {
    awk '/^PPid:/ {print $2}' "/proc/$1/status" 2>/dev/null
}

# Read a single KEY=value from /proc/<pid>/environ (e.g. KITTY_PID).
proc_environ_var() {
    local pid=$1 key=$2
    [[ -r "/proc/$pid/environ" ]] || return 1
    tr '\0' '\n' < "/proc/$pid/environ" \
        | awk -F= -v k="$key" '$1 == k { print substr($0, length(k) + 2); exit }'
}

# A holder is live only if the pid exists *and* was started at the same moment
# we recorded. Without the starttime check, a recycled pid could keep the
# machine awake indefinitely after a crash. Manual holders are always
# "pid-live"; reconcile_con drops them when the container is gone.
holder_live() {
    local file=$1 pid=${1##*/} recorded now

    # Only ever treat regular files as holders. A stray directory here would
    # otherwise be read as a pid and then removed.
    [[ -f "$file" ]] || return 1
    [[ "$pid" == "manual" ]] && return 0
    [[ -d "/proc/$pid" ]] || return 1

    recorded=$(cut -d' ' -f1 < "$file" 2>/dev/null) || return 1
    [[ -n "$recorded" ]] || return 1
    now=$(proc_starttime "$pid") || return 1
    [[ "$recorded" == "$now" ]]
}

holder_label() {
    cut -d' ' -f2- < "$1" 2>/dev/null
}

has_manual_holder() {
    local dir
    for dir in "$STATE_DIR"/*/; do
        [[ -e "${dir}manual" ]] && return 0
    done
    return 1
}

# --- sway --------------------------------------------------------------------

sway_pid_map() {
    swaymsg -t get_tree | jq -r '.. | objects | select(.pid != null and .id != null) | "\(.pid) \(.id)"'
}

con_exists() {
    local con=$1
    [[ -n "$con" ]] || return 1
    swaymsg -t get_tree \
        | jq -e --argjson id "$con" 'any(.. | objects; .id == $id)' >/dev/null 2>&1
}

# Current user inhibit mode for a container (none|focus|fullscreen|open|visible).
user_inhibit_mode() {
    local con=$1
    swaymsg -t get_tree \
        | jq -r --argjson id "$con" \
            '.. | objects | select(.id == $id) | .idle_inhibitors.user // "none"' \
        | head -1
}

# True when pid (or an ancestor) looks like a graphical terminal session.
# Used to gate the focused-window fallback so arbitrary pids (e.g. pid 1)
# cannot pin the focused container awake forever.
session_looks_graphical() {
    local walk=$1
    while [[ -n "$walk" && "$walk" != 0 && "$walk" != 1 ]]; do
        if proc_environ_var "$walk" KITTY_PID >/dev/null \
            || proc_environ_var "$walk" TMUX >/dev/null \
            || proc_environ_var "$walk" WAYLAND_DISPLAY >/dev/null; then
            return 0
        fi
        walk=$(proc_ppid "$walk") || return 1
        [[ -n "$walk" ]] || return 1
    done
    return 1
}

# Walk up the process tree until we hit a pid Sway knows about. An agent runs
# several levels below its terminal, and the terminal owns the surface.
#
# Fallbacks (needed for tmux, whose server sits between the shell and kitty):
#   1. KITTY_PID from the process or an ancestor's environ
#   2. focused container — only for graphical sessions (see above)
con_id_for_pid() {
    local pid=$1 map id walk kitty_pid

    map=$(sway_pid_map) || return 1

    walk=$pid
    while [[ -n "$walk" && "$walk" != 0 && "$walk" != 1 ]]; do
        id=$(awk -v p="$walk" '$1 == p {print $2; exit}' <<<"$map")
        if [[ -n "$id" ]]; then
            printf '%s' "$id"
            return 0
        fi
        walk=$(proc_ppid "$walk") || return 1
        [[ -n "$walk" ]] || return 1
    done

    walk=$pid
    while [[ -n "$walk" && "$walk" != 0 && "$walk" != 1 ]]; do
        kitty_pid=$(proc_environ_var "$walk" KITTY_PID || true)
        if [[ -n "${kitty_pid:-}" ]]; then
            id=$(awk -v p="$kitty_pid" '$1 == p {print $2; exit}' <<<"$map")
            if [[ -n "$id" ]]; then
                printf '%s' "$id"
                return 0
            fi
        fi
        walk=$(proc_ppid "$walk") || break
        [[ -n "$walk" ]] || break
    done

    if session_looks_graphical "$pid"; then
        id=$(focused_con_id)
        if [[ -n "$id" && "$id" != "null" ]]; then
            echo "idle-inhibit: no window for pid $pid; using focused con $id" >&2
            printf '%s' "$id"
            return 0
        fi
    fi

    return 1
}

focused_con_id() {
    swaymsg -t get_tree | jq -r 'recurse(.nodes[]?, .floating_nodes[]?) | select(.focused == true) | .id' | head -1
}

set_inhibit() {
    local con=$1 mode=$2
    # A closed window matches nothing; that is not an error worth surfacing.
    swaymsg "[con_id=$con] inhibit_idle $mode" >/dev/null 2>&1 || true
}

# --- core --------------------------------------------------------------------

# Reconcile Sway's inhibitor for one container against its live holders.
# Prints the surviving holder count.
#
# On the way to zero holders we restore the previous user inhibit mode so
# for_window rules (e.g. mpv focus, firefox fullscreen) are not wiped to none.
reconcile_con() {
    local con=$1 file live=0 dir prev

    # An empty con id would make $dir the state root and walk every container.
    [[ -n "$con" ]] || return 0
    # Assigned separately: `local` expands all its words before assigning any,
    # so "$STATE_DIR/$con" on the line above would see an empty $con.
    dir="$STATE_DIR/$con"

    if [[ -d "$dir" ]] && ! con_exists "$con"; then
        rm -rf "$dir"
        printf '0'
        return 0
    fi

    if [[ -d "$dir" ]]; then
        for file in "$dir"/*; do
            [[ -e "$file" ]] || continue
            if holder_live "$file"; then
                live=$((live + 1))
            else
                rm -f "$file"
            fi
        done
    fi

    if (( live > 0 )); then
        # Save the pre-hold mode once, before we overwrite it with open.
        if [[ ! -f "$dir/.prev_mode" ]]; then
            prev=$(user_inhibit_mode "$con" 2>/dev/null || echo none)
            [[ -n "$prev" && "$prev" != "null" ]] || prev=none
            # If we already own open from a prior crash, don't "restore" to open.
            [[ "$prev" == "open" ]] && prev=none
            printf '%s\n' "$prev" > "$dir/.prev_mode"
        fi
        set_inhibit "$con" open
    else
        prev=none
        if [[ -f "$dir/.prev_mode" ]]; then
            prev=$(<"$dir/.prev_mode")
            rm -f "$dir/.prev_mode"
        fi
        [[ -n "$prev" ]] || prev=none
        set_inhibit "$con" "$prev"
        rmdir "$dir" 2>/dev/null || true
    fi

    printf '%s' "$live"
}

reconcile_all() {
    local dir
    for dir in "$STATE_DIR"/*/; do
        [[ -d "$dir" ]] || continue
        dir=${dir%/}
        reconcile_con "${dir##*/}" >/dev/null
    done
}

# True when any holder file is stale. Pure filesystem work — cheap enough to
# call from the status bar every second, and it keeps the reaper running even
# if a holder is SIGKILLed and never releases.
has_stale_holder() {
    local dir file
    for dir in "$STATE_DIR"/*/; do
        [[ -d "$dir" ]] || continue
        for file in "$dir"*; do
            [[ -e "$file" ]] || continue
            holder_live "$file" || return 0
        done
    done
    return 1
}

cmd_acquire() {
    local pid=$1 label=$2 con=$3

    ensure_sway || return 1

    if [[ -z "$con" ]]; then
        if ! con=$(con_id_for_pid "$pid"); then
            echo "idle-inhibit: no Sway window owns pid $pid; not inhibiting" >&2
            return 1
        fi
    fi

    [[ -n "$label" ]] || label=$(proc_comm "$pid")

    lock
    mkdir -p "$STATE_DIR/$con"
    printf '%s %s\n' "$(proc_starttime "$pid")" "$label" > "$STATE_DIR/$con/$pid"
    reconcile_con "$con" >/dev/null

    echo "idle-inhibit: holding (con $con, $label)"
}

cmd_release() {
    local pid=$1 con=$2

    ensure_sway || return 1

    if [[ -z "$con" ]]; then
        # The window may already be gone, so fall back to whichever container
        # actually recorded this pid rather than re-deriving it from the tree.
        con=$(con_id_for_pid "$pid" 2>/dev/null || true)
    fi

    lock
    if [[ -n "$con" && -e "$STATE_DIR/$con/$pid" ]]; then
        rm -f "$STATE_DIR/$con/$pid"
        reconcile_con "$con" >/dev/null
    else
        local dir
        for dir in "$STATE_DIR"/*/; do
            [[ -e "$dir$pid" ]] || continue
            rm -f "$dir$pid"
            dir=${dir%/}
            reconcile_con "${dir##*/}" >/dev/null
        done
    fi
}

cmd_toggle() {
    local con

    ensure_sway || return 1

    con=$(focused_con_id)
    if [[ -z "$con" || "$con" == "null" ]]; then
        echo "idle-inhibit: no focused window" >&2
        return 1
    fi

    lock
    if [[ -e "$STATE_DIR/$con/manual" ]]; then
        rm -f "$STATE_DIR/$con/manual"
        reconcile_con "$con" >/dev/null
        echo "idle-inhibit: manual hold off (con $con)"
    else
        mkdir -p "$STATE_DIR/$con"
        printf 'manual manual\n' > "$STATE_DIR/$con/manual"
        reconcile_con "$con" >/dev/null
        echo "idle-inhibit: manual hold on (con $con)"
    fi
}

cmd_status() {
    local dir file labels=() label

    [[ -d "$STATE_DIR" ]] || return 0

    # Pid-stale holders are cheap to detect on the filesystem. Manual holders
    # can outlive their window, so those force a reconcile (con check) too.
    if has_stale_holder || has_manual_holder; then
        lock
        ensure_sway >/dev/null 2>&1 && reconcile_all
    fi

    for dir in "$STATE_DIR"/*/; do
        [[ -d "$dir" ]] || continue
        for file in "$dir"*; do
            [[ -e "$file" ]] || continue
            holder_live "$file" || continue
            label=$(holder_label "$file")
            labels+=("${label:-?}")
        done
    done

    (( ${#labels[@]} )) || return 0

    printf '%s' "$(printf '%s\n' "${labels[@]}" | sort -u | paste -sd, -)"
}

cmd_list() {
    local dir file con state

    [[ -d "$STATE_DIR" ]] || { echo "no holders"; return 0; }

    for dir in "$STATE_DIR"/*/; do
        [[ -d "$dir" ]] || continue
        dir=${dir%/}
        con=${dir##*/}
        for file in "$dir"/*; do
            [[ -e "$file" ]] || continue
            holder_live "$file" && state=live || state=stale
            printf 'con %-6s %-10s %-6s %s\n' "$con" "${file##*/}" "$state" "$(holder_label "$file")"
        done
    done
}

main() {
    local cmd="" pid="" label="" con=""

    cmd=${1:-}
    shift || true

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --pid)   pid=${2:-}; shift 2 ;;
            --label) label=${2:-}; shift 2 ;;
            --con)   con=${2:-}; shift 2 ;;
            *) usage >&2; exit 1 ;;
        esac
    done

    [[ -n "$pid" ]] || pid=$PPID

    case "$cmd" in
        acquire) cmd_acquire "$pid" "$label" "$con" ;;
        release) cmd_release "$pid" "$con" ;;
        toggle)  cmd_toggle ;;
        status)  cmd_status ;;
        list)    cmd_list ;;
        reap)    lock; ensure_sway >/dev/null 2>&1 && reconcile_all ;;
        -h|--help|help) usage ;;
        *) usage >&2; exit 1 ;;
    esac
}

main "$@"
