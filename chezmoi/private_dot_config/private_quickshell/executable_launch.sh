#!/bin/bash
# Restart quickshell. sway runs this from exec_always, so it fires on every
# config reload as well as at login.
#
# quickshell reloads its own QML when a file under ~/.config/quickshell changes,
# so this is only about the sway side: exec_always would otherwise leave the old
# instance running next to a new one, and two bars would fight over the same
# exclusive zone.

set -u

qs kill >/dev/null 2>&1 || true

# qs kill returns before the process is gone. Give it two seconds, then start
# anyway: a leftover instance is a visible double bar, a shell that never starts
# is an invisible failure.
#
# The pattern matches both names. The package ships /usr/bin/qs and
# /usr/bin/quickshell, and the process takes the name it was invoked under, which
# for a daemon started from here is `qs`. Matching only `quickshell` made this
# loop break on the first pass and wait for nothing.
for _ in $(seq 20); do
    pgrep -u "$UID" -x "qs|quickshell" >/dev/null || break
    sleep 0.1
done

qs --daemonize
