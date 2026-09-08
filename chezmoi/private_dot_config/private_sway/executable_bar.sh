#!/bin/bash
# Pick a status bar and start it. sway runs this from exec_always, so it fires at
# login and again on every config reload.
#
# The choice happens here, at start, rather than in a chezmoi template at apply
# time. chezmoi reads .chezmoiignore while it builds the source state, before any
# run_once_before_ script has installed anything, so a template branch on
# `lookPath "qs"` is one apply behind on a fresh machine. Deciding at start also
# means installing quickshell on a machine that has been running waybar costs a
# sway reload and nothing else.
#
# Both bar configurations are deployed either way. They are inert files; the one
# that does not run costs a few kilobytes in ~/.config.
#
# quickshell wins when both are installed. It is the bar this repo maintains.
# waybar stays for distributions that do not package quickshell, which is Debian,
# Ubuntu and Fedora at the time of writing.

set -u

if command -v qs >/dev/null 2>&1; then
    # A leftover waybar from before quickshell was installed would sit next to it
    # and claim its own exclusive zone. Its own launcher never sees this case,
    # because sway no longer starts it.
    pkill -x waybar 2>/dev/null || true
    exec ~/.config/quickshell/launch.sh
fi

if command -v waybar >/dev/null 2>&1; then
    # Both names, because the package installs qs and quickshell as two entry
    # points and the process carries whichever one started it.
    pkill -x "qs|quickshell" 2>/dev/null || true
    exec ~/.config/waybar/launch.sh
fi

# Neither is installed. A session with no bar reads as broken rather than as
# incomplete, and nobody goes looking in the sway log for an exec_always that
# said nothing. mako is D-Bus activatable, so this works even though the config
# starts mako a few lines further down.
echo "bar.sh: neither quickshell nor waybar is installed" >&2
notify-send -u critical "No status bar" \
    "Neither quickshell nor waybar is installed. Install one, then reload sway with Mod+Shift+c."
