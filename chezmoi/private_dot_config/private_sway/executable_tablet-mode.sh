#!/usr/bin/env bash
# React to the keyboard cover being detached or reattached.
#
# The ROG Flow Z13's "Asus WMI hotkeys" input device carries SW_TABLET_MODE
# (SW=2 in /proc/bus/input/devices), so sway's `bindswitch tablet:on|off` fires
# here. With the cover off there is no physical keyboard at all, so the
# on-screen keyboard comes up and the titlebars grow enough to hit with a thumb.

set -u

case "${1:-}" in
    on)
        swaymsg gaps inner all set 4 >/dev/null
        swaymsg default_border pixel 6 >/dev/null
        command -v wvkbd-mobintl >/dev/null 2>&1 && \
            pgrep -x wvkbd-mobintl >/dev/null || \
            wvkbd-mobintl -L 260 --hidden >/dev/null 2>&1 &
        notify-send -t 2000 "Tablet mode" "keyboard cover detached"
        ;;
    off)
        swaymsg gaps inner all set 8 >/dev/null
        swaymsg default_border pixel 3 >/dev/null
        pkill -x wvkbd-mobintl
        notify-send -t 2000 "Laptop mode" "keyboard cover attached"
        ;;
    *)
        echo "usage: $0 on|off" >&2
        exit 2
        ;;
esac
