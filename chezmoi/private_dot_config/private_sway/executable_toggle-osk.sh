#!/usr/bin/env bash
# Show or hide the on-screen keyboard.
#
# wvkbd is started hidden by tablet-mode.sh and listens for SIGUSR2 (show) and
# SIGUSR1 (hide), so toggling is a signal rather than a restart. If it is not
# running at all, start it visible.

set -u

if ! command -v wvkbd-mobintl >/dev/null 2>&1; then
    notify-send "No on-screen keyboard" "install wvkbd"
    exit 1
fi

if pgrep -x wvkbd-mobintl >/dev/null; then
    if [ -f "${XDG_RUNTIME_DIR:-/tmp}/wvkbd.shown" ]; then
        pkill -USR1 -x wvkbd-mobintl
        rm -f "${XDG_RUNTIME_DIR:-/tmp}/wvkbd.shown"
    else
        pkill -USR2 -x wvkbd-mobintl
        touch "${XDG_RUNTIME_DIR:-/tmp}/wvkbd.shown"
    fi
else
    wvkbd-mobintl -L 260 >/dev/null 2>&1 &
    touch "${XDG_RUNTIME_DIR:-/tmp}/wvkbd.shown"
fi
