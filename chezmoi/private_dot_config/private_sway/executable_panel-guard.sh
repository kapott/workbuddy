#!/usr/bin/env bash
# Re-enable the internal panel when sway is left with no active output at all.
#
# `display.sh external-only` disables the panel while an external is up. That is
# a runtime state, not config, so it outlives the external: unplug the cable and
# sway has zero enabled outputs. There is no key to press at that point, because
# nothing is drawn to see what you are pressing.
#
# kanshi normally catches this. Its `tablet` profile lists eDP-1 alone, so losing
# the external flips the matched profile and re-enables the panel. That is one
# unsupervised process started with `exec kanshi`, and it only helps when the
# remaining outputs match a profile it has. An unknown projector at a client site
# matches nothing. This guard is the floor under both cases: it does not care
# which outputs exist, only that at least one is on.
#
# Lifetime is tied to sway the same way autorotate.sh does it. sway does not
# reliably reap what `exec` starts, and a blocking read on an idle IPC
# subscription would sit there long after the session is gone.

set -u

PANEL="${SWAY_PANEL_OUTPUT:-eDP-1}"
LOCK="${XDG_RUNTIME_DIR:-/tmp}/sway-panel-guard.lock"

# How long to wait after an output event before judging the result. kanshi reacts
# to the same event; give it room to apply its profile first, so the common case
# stays kanshi's and this only fires when kanshi did not.
SETTLE="${SWAY_PANEL_GUARD_SETTLE:-1}"

if ! command -v jq >/dev/null 2>&1; then
    echo "panel-guard: jq not found, cannot read output state" >&2
    exit 0
fi

# Single instance, via a lock held for the life of the process. Matching on the
# process list would also match the shell that launched it.
exec 9>"$LOCK"
if ! flock -n 9; then
    echo "panel-guard: another instance holds $LOCK" >&2
    exit 0
fi

outputs() { swaymsg -t get_outputs -r 2>/dev/null; }

sway_gone() {
    [ -n "${SWAYSOCK:-}" ] && [ ! -S "$SWAYSOCK" ]
}

# Empty output means swaymsg failed, which happens while sway is shutting down.
# Report 1 there so a failed query never looks like an emergency.
count_active() {
    local json n
    json="$(outputs)" || return
    [ -n "$json" ] || { echo 1; return; }
    n="$(printf '%s' "$json" | jq -r '[.[] | select(.active)] | length' 2>/dev/null)"
    echo "${n:-1}"
}

panel_present() {
    outputs | jq -e --arg p "$PANEL" 'any(.[]; .name == $p)' >/dev/null 2>&1
}

rescue() {
    [ "$(count_active)" = 0 ] || return 0
    # Nothing to fall back to if the panel itself is gone; an external-only
    # desktop with the cable pulled is genuinely dark and that is not our call.
    panel_present || return 0

    swaymsg output "$PANEL" enable >/dev/null 2>&1 || return 0
    # The sway config parks eDP-1 at 3840,320 for the docked layout. Alone at
    # that offset it still renders, but internal-only normalises it and so do we.
    swaymsg output "$PANEL" position 0 0 >/dev/null 2>&1

    command -v notify-send >/dev/null 2>&1 &&
        notify-send -t 4000 "Displays" "No output was left on, re-enabled $PANEL"
    echo "panel-guard: no active output left, re-enabled $PANEL"
}

sub_pid=""
cleanup() {
    [ -n "$sub_pid" ] && kill "$sub_pid" 2>/dev/null
}
trap cleanup EXIT INT TERM

# Process substitution rather than a pipe, so the loop runs in this shell and
# `break` leaves it with the trap still able to fire. -r keeps one event per
# line, which is what the read below assumes.
exec 3< <(swaymsg -t subscribe -m -r '["output"]' 2>/dev/null)
sub_pid=$!

# A session can start in the bad state: sway reloaded while external-only was in
# effect, or the guard was restarted by hand after the fact.
rescue

while :; do
    if read -r -t 5 _ <&3; then
        sleep "$SETTLE"
        rescue
    else
        status=$?
        # A timeout returns >128. Anything else means the subscription ended,
        # so sway is gone or swaymsg died and there is nothing left to watch.
        [ "$status" -gt 128 ] || break
        sway_gone && break
    fi
done
