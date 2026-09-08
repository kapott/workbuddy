#!/usr/bin/env bash
# Blank the built-in panel on lid close, but only when something else can show.
#
# On a detachable this matters more than on a laptop: an unguarded
# `bindswitch lid:on output eDP-1 disable` leaves you with a dark machine and no
# way to see that you have one workspace left. Count the other active outputs
# first and do nothing if the panel is all there is.

set -u

PANEL="${SWAY_PANEL_OUTPUT:-eDP-1}"

others() {
    swaymsg -t get_outputs -r |
        jq "[.[] | select(.name != \"$PANEL\" and .active == true)] | length"
}

case "${1:-}" in
    close)
        if [ "$(others)" -gt 0 ]; then
            swaymsg output "$PANEL" disable >/dev/null
        fi
        ;;
    open)
        swaymsg output "$PANEL" enable >/dev/null
        ;;
    *)
        echo "usage: $0 close|open" >&2
        exit 2
        ;;
esac
