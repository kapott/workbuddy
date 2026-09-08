#!/usr/bin/env bash
# Follow the built-in accelerometer and rotate the tablet panel with it.
#
# sway has no auto-rotation of its own. iio-sensor-proxy exposes the ROG Flow
# Z13's accel_3d device over D-Bus and monitor-sensor prints a line per change;
# this turns those lines into `swaymsg output ... transform`.
#
# The touchscreen and stylus have to be rotated too. map_to_output alone does not
# do that: the pointer axes stay in panel coordinates and taps end up mirrored.
#
# Lifetime is tied to sway on purpose. sway does not reliably reap what it starts
# with `exec`, and monitor-sensor can sit silent for hours, so a plain blocking
# read leaves this process and its sensor child alive long after the session is
# gone. That is not theoretical: a nested sway run left two of these behind. The
# read below times out instead, and every timeout re-checks the IPC socket.

set -u

OUTPUT="${SWAY_ROTATE_OUTPUT:-eDP-1}"
LOCK="${XDG_RUNTIME_DIR:-/tmp}/sway-autorotate.lock"

if ! command -v monitor-sensor >/dev/null 2>&1; then
    echo "autorotate: monitor-sensor not found, install iio-sensor-proxy" >&2
    exit 0
fi

# Single instance, via a lock this process holds for as long as it runs. A
# pattern match on the process list would also match the shell that launched it,
# which is a good way to kill the wrong thing.
exec 9>"$LOCK"
if ! flock -n 9; then
    echo "autorotate: another instance holds $LOCK" >&2
    exit 0
fi

apply() {
    local transform="$1"
    swaymsg output "$OUTPUT" transform "$transform" >/dev/null || return
    # Re-pin the touch devices so their axes follow the new orientation.
    swaymsg input type:touch map_to_output "$OUTPUT" >/dev/null
    swaymsg input type:tablet_tool map_to_output "$OUTPUT" >/dev/null
}

sway_gone() {
    [ -n "${SWAYSOCK:-}" ] && [ ! -S "$SWAYSOCK" ]
}

sensor_pid=""
cleanup() {
    [ -n "$sensor_pid" ] && kill "$sensor_pid" 2>/dev/null
}
trap cleanup EXIT INT TERM

# Process substitution rather than a pipe, so the loop runs in this shell and
# `break` really leaves it with the trap still able to fire.
exec 3< <(monitor-sensor --accel 2>/dev/null)
sensor_pid=$!

while :; do
    if read -r -t 5 line <&3; then
        # monitor-sensor prints "=== Has accelerometer (orientation: normal)"
        # once, then "Accelerometer orientation changed: left-up" per move.
        case "$line" in
            *normal*)    apply normal ;;
            *bottom-up*) apply 180 ;;
            *left-up*)   apply 90 ;;
            *right-up*)  apply 270 ;;
        esac
    else
        status=$?
        # A timeout returns >128. Anything else means the stream ended, which
        # means monitor-sensor is gone and there is nothing left to follow.
        [ "$status" -gt 128 ] || break
        sway_gone && break
    fi
done
