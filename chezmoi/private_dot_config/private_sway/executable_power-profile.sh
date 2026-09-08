#!/usr/bin/env bash
# Read and switch the ASUS platform profile, for both the ROG key and the bar.
#
# One script rather than two call sites because the asusctl CLI has already
# changed shape once: `asusctl profile -n` and `-p` were valid in 5.x and are
# rejected outright by 6.4.0, which turned them into `next` and `get`. The sway
# binding kept the old flags and silently did nothing, because the command exited
# with a usage error and the `&&` meant even the notification never fired. With
# the invocation in one place the next rename breaks one file, visibly.
#
# asusd and power-profiles-daemon are both running here and both write
# /sys/firmware/acpi/platform_profile under different names for the same three
# states. Whichever writes last wins. This script deliberately speaks only
# asusctl, matching the ROG key and the fan curves that asusd also owns.
#
# asusd switches on its own when the power source changes (AC and battery each
# have their own profile), so the indicator polls rather than trusting the last
# value it wrote.

set -u

# The bar reads this file instead of running asusctl itself, and watches it for
# changes. That is what makes a press of the ROG fan key repaint the indicator:
# the key runs this script, the script rewrites the file, the watch fires.
# $XDG_RUNTIME_DIR is a tmpfs cleared at logout, which is the right lifetime for
# a value that only describes the running session.
STATE="${XDG_RUNTIME_DIR:-/tmp}/power-profile"

die() { echo "$0: $*" >&2; exit 1; }

command -v asusctl >/dev/null 2>&1 || die "asusctl is not installed"

# `asusctl profile get` prints:
#   Active profile: Performance
#
#   AC profile Performance
#   Battery profile Quiet
active() {
    asusctl profile get 2>/dev/null |
        sed -n 's/^Active profile:[[:space:]]*//p' | head -1
}

on_ac()      { asusctl profile get 2>/dev/null | sed -n 's/^AC profile[[:space:]]*//p' | head -1; }
on_battery() { asusctl profile get 2>/dev/null | sed -n 's/^Battery profile[[:space:]]*//p' | head -1; }

# Three lines: the active profile, then the two asusd will switch to by itself
# when the power source changes. The bar shows the first and puts the other two
# in the tooltip, which is where the surprise usually is - what you set by hand
# does not survive plugging in.
#
# Written to a temporary file and moved into place, so a reader watching the file
# never sees a half-written name.
publish() {
    printf '%s\n%s\n%s\n' \
        "$(active)" "$(on_ac)" "$(on_battery)" > "$STATE.tmp" &&
        mv "$STATE.tmp" "$STATE"
}

notify() {
    command -v notify-send >/dev/null 2>&1 &&
        notify-send -t 2000 -h "string:x-canonical-private-synchronous:asus-profile" \
            "Power profile" "$1"
}

case "${1:-get}" in
    get)     active ;;
    publish) publish ;;
    next)
        asusctl profile next >/dev/null 2>&1 || die "asusctl profile next failed"
        notify "$(active)"
        publish
        ;;
    set)
        [ "$#" -ge 2 ] || die "usage: $0 set <Quiet|Balanced|Performance>"
        asusctl profile set "$2" >/dev/null 2>&1 || die "asusctl profile set $2 failed"
        notify "$(active)"
        publish
        ;;
    list)   asusctl profile list ;;
    -h|--help|help)
        cat <<USAGE
usage: $0 <command>

  get                    print the active profile (default)
  publish                write the profile state to $STATE for the bar
  next                   cycle to the next profile, notify, publish
  set <profile>          set one of Quiet, Balanced, Performance
  list                   profiles asusd offers

asusd applies its own profile when the power source changes, so what you set by
hand does not survive plugging in. Change that with:

  asusctl profile set -a Performance     # what to use on AC
  asusctl profile set -b Quiet           # what to use on battery
USAGE
        ;;
    *) die "unknown command: $1" ;;
esac
