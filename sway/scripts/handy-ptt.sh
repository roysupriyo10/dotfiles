#!/bin/sh
# handy-ptt.sh — deterministic Bluetooth push-to-talk for Handy.
#
# Classic Bluetooth can do A2DP (music) XOR HFP (mic), never both, so dictating
# on a BT headset means switching A2DP->HFP and back. The naive "just send the
# signal" approach loses the start of your speech (the SCO link isn't up yet) and
# leaves the headset stranded in HFP with the music paused.
#
# This wrapper makes both edges deterministic, macOS-style:
#   start (key press):   pause whatever is playing -> switch headset to HFP ->
#                        open a throwaway capture to warm the SCO link -> wait
#                        until it is actually streaming -> crank mic to 100% ->
#                        start Handy (its start-beep is your "speak now" cue).
#   stop  (key release): stop+transcribe -> drop the warmer -> restore A2DP ->
#                        resume exactly the players we paused.
#
# Falls back to the default (built-in) mic when no BT headset is connected.
#
# Usage: handy-ptt.sh start|stop [SIGNAL]   (SIGNAL defaults to USR2 = transcribe;
#        pass USR1 for transcribe + LLM post-processing)

SIG="${2:-USR2}"
CARD=$(pactl list cards short | awk '/bluez_card/{print $2; exit}')
SRC=$(pactl list sources short | awk '/bluez_input/{print $2; exit}')
DIR="$XDG_RUNTIME_DIR/handy-ptt"
mkdir -p "$DIR"
LOG="$DIR/ptt.log"
log(){ echo "$(date +%H:%M:%S.%3N) [$$ $1$2] $3" >> "$LOG"; }

log "$1" "$SIG" "invoked (CARD=${CARD:-none} SRC=${SRC:-none})"

# Serialize start vs stop so a quick tap can't interleave them and orphan the
# warmer / strand the headset in HFP. Wait up to 5s but proceed on timeout —
# restore is idempotent and must never be skipped.
exec 9>"$DIR/lock"
flock -w 5 9 || log "$1" "$SIG" "WARN: flock timed out, proceeding without lock"
log "$1" "$SIG" "lock acquired"

case "$1" in
  start)
    if [ -z "$CARD" ]; then              # no BT headset -> default (built-in) mic
      pactl set-source-volume @DEFAULT_SOURCE@ 100% 2>/dev/null
      pkill -"$SIG" -x handy
      exit 0
    fi
    # remember + pause only the players that are currently playing
    : > "$DIR/players"
    for p in $(playerctl -l 2>/dev/null); do
      [ "$(playerctl -p "$p" status 2>/dev/null)" = "Playing" ] && echo "$p" >> "$DIR/players"
    done
    while read -r p; do playerctl -p "$p" pause 2>/dev/null; done < "$DIR/players"
    # remember the current profile, then switch to HFP
    pactl list cards | awk -v c="$CARD" '$0~c{f=1} f&&/Active Profile/{print $3; exit}' > "$DIR/profile"
    pactl set-card-profile "$CARD" headset-head-unit
    # warm the SCO link with a throwaway capture. 9>&- closes the lock fd in the
    # child so the backgrounded warmer does NOT hold the lock (which would
    # deadlock the matching `stop`).
    pw-record --target "$SRC" /dev/null >/dev/null 2>&1 9>&- &
    echo $! > "$DIR/warmer"
    pactl set-source-volume "$SRC" 100% 2>/dev/null
    # gate: wait until the mic is genuinely streaming (~130ms on QC Ultra), max 1s
    for _ in $(seq 1 50); do
      [ "$(pactl list sources short | awk -v s="$SRC" '$2==s{print $NF}')" = "RUNNING" ] && break
      sleep 0.02
    done
    sleep 0.1                            # small cushion past the first frames
    pactl set-source-volume "$SRC" 100% 2>/dev/null   # re-assert once node is live
    pkill -"$SIG" -x handy               # start recording; the start-beep = "speak"
    ;;
  stop)
    pkill -"$SIG" -x handy               # stop + transcribe
    if [ -f "$DIR/warmer" ]; then kill "$(cat "$DIR/warmer")" 2>/dev/null; rm -f "$DIR/warmer"; fi
    pkill -x pw-record 2>/dev/null       # belt-and-suspenders: kill any stray warmer
    [ -n "$CARD" ] && pactl set-card-profile "$CARD" "$(cat "$DIR/profile" 2>/dev/null || echo a2dp-sink)"
    if [ -f "$DIR/players" ]; then
      while read -r p; do playerctl -p "$p" play 2>/dev/null; done < "$DIR/players"
      rm -f "$DIR/players"
    fi
    ;;
esac
