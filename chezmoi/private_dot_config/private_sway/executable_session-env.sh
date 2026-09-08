#!/usr/bin/env bash
# Publish this sway session's variables to the systemd user manager and to
# D-Bus activation, but only when this sway actually owns the session.
#
# Why the guard. The systemd user manager is per user, not per session, so a
# plain `systemctl --user import-environment WAYLAND_DISPLAY ...` from a sway
# started inside another compositor overwrites that compositor's values for
# everyone. Quitting sway does not put them back. The host session is then left
# pointing at a socket that no longer exists, and every app it launches as a
# systemd user unit dies on startup: KDE with KDE_APPLICATIONS_AS_SCOPE=1 shows
# this as "Failed to create wl_display" and a core dump, while apps started from
# a terminal keep working because they inherit a good environment from their
# parent. That asymmetry makes it read like one broken application rather than a
# broken session.
#
# Arch's /etc/sway/config.d/50-systemd-user.conf does the same import with no
# guard, which is why the sway config no longer includes /etc/sway/config.d/*
# and does this work here instead.

set -u

ours="${WAYLAND_DISPLAY:-}"
if [ -z "$ours" ]; then
    exit 0
fi

existing="$(systemctl --user show-environment 2>/dev/null | sed -n 's/^WAYLAND_DISPLAY=//p')"

# Is another compositor still holding that display? A Wayland compositor keeps
# an exclusive flock on <display>.lock for as long as it runs, so a lock we can
# take is a stale leftover and a lock we cannot take means someone is alive.
compositor_alive() {
    local display="$1"
    local sock="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/$display"
    [ -S "$sock" ] || return 1
    if command -v flock >/dev/null 2>&1 && [ -e "$sock.lock" ]; then
        flock -n "$sock.lock" true && return 1
    fi
    return 0
}

if [ -n "$existing" ] && [ "$existing" != "$ours" ] && compositor_alive "$existing"; then
    echo "sway: nested under $existing, leaving the systemd user environment alone" >&2
    exit 0
fi

systemctl --user set-environment XDG_CURRENT_DESKTOP=sway
systemctl --user import-environment DISPLAY SWAYSOCK WAYLAND_DISPLAY XDG_CURRENT_DESKTOP

if command -v dbus-update-activation-environment >/dev/null 2>&1; then
    dbus-update-activation-environment --systemd \
        DISPLAY SWAYSOCK WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway
fi
