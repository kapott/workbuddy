#!/usr/bin/env bash
# Arrange, disable and re-enable outputs from one place.
#
# Everything here is runtime only: it talks to the running sway through
# `swaymsg output`, it does not write config. kanshi still owns what happens on
# hotplug, so unplugging and replugging returns to the profile in
# ~/.config/kanshi/config. That split is deliberate. This script is for the
# unknown projector in a meeting room, kanshi is for the desk you sit at daily.
#
# Positions are read back from sway after enabling an output rather than
# computed from mode and scale. The panel on the Z13 runs at scale 1.25, so its
# 2560x1600 mode is 2048x1280 logical, and hand-computed geometry gets that
# wrong in exactly one place and leaves a gap you only notice with a cursor.
#
# There is no mirror subcommand. Sway has no clone mode, and putting two outputs
# at the same position does not mirror: each output still shows its own
# workspace. Mirroring needs wl-mirror, a separate client, which is not
# installed here on purpose.

set -uo pipefail

PANEL="${SWAY_PANEL_OUTPUT:-eDP-1}"

die() { echo "$0: $*" >&2; exit 1; }

command -v jq >/dev/null || die "jq is required"

outputs() { swaymsg -t get_outputs -r; }

# All connected outputs, panel first. Sway lists a connected but disabled output
# with active=false, and omits a disconnected one entirely.
all_names() {
    outputs | jq -r --arg p "$PANEL" \
        '[.[] | select(.name == $p)] + [.[] | select(.name != $p)] | .[].name'
}

external_names() {
    outputs | jq -r --arg p "$PANEL" '.[] | select(.name != $p) | .name'
}

active_names() {
    outputs | jq -r '.[] | select(.active) | .name'
}

count_active() { active_names | grep -c . ; }

has() { all_names | grep -qx "$1"; }

rect_of() {
    outputs | jq -r --arg n "$1" '.[] | select(.name == $n) | "\(.rect.width) \(.rect.height)"'
}

notify() {
    command -v notify-send >/dev/null && notify-send -t 2500 "Displays" "$1"
    echo "$1"
}

# Place the named outputs in a row or a column, in the order given, centered on
# the perpendicular axis. Everything is enabled first, because an output that is
# still disabled reports a zero rect and would stack on top of its neighbour.
place() {
    local axis="$1"; shift
    local names=("$@")
    local n w h

    for n in "${names[@]}"; do
        swaymsg output "$n" enable >/dev/null || die "cannot enable $n"
    done

    local -a ws hs
    local span=0
    for n in "${names[@]}"; do
        read -r w h <<<"$(rect_of "$n")"
        [ -n "${w:-}" ] || die "no geometry for $n"
        ws+=("$w"); hs+=("$h")
        if [ "$axis" = row ]; then
            [ "$h" -gt "$span" ] && span="$h"
        else
            [ "$w" -gt "$span" ] && span="$w"
        fi
    done

    local pos=0 i=0 x y
    for n in "${names[@]}"; do
        if [ "$axis" = row ]; then
            x="$pos"; y=$(( (span - hs[i]) / 2 )); pos=$(( pos + ws[i] ))
        else
            y="$pos"; x=$(( (span - ws[i]) / 2 )); pos=$(( pos + hs[i] ))
        fi
        swaymsg output "$n" position "$x" "$y" >/dev/null || die "cannot position $n"
        i=$(( i + 1 ))
    done
}

extend() {
    local dir="${1:-right}" target="${2:-}"
    local -a ext
    if [ -n "$target" ]; then
        has "$target" || die "no such output: $target"
        ext=("$target")
    else
        mapfile -t ext < <(external_names)
    fi
    [ "${#ext[@]}" -gt 0 ] || die "no external output connected"

    case "$dir" in
        right) place row  "$PANEL" "${ext[@]}" ;;
        left)  place row  "${ext[@]}" "$PANEL" ;;
        down)  place col  "$PANEL" "${ext[@]}" ;;
        up)    place col  "${ext[@]}" "$PANEL" ;;
        *) die "direction must be right, left, up or down" ;;
    esac
    notify "Extended ${dir}: ${ext[*]}"
}

internal_only() {
    has "$PANEL" || die "panel $PANEL is not connected"
    place row "$PANEL"
    local n
    for n in $(external_names); do
        swaymsg output "$n" disable >/dev/null
    done
    notify "Internal only: $PANEL"
}

external_only() {
    local -a ext
    mapfile -t ext < <(external_names)
    [ "${#ext[@]}" -gt 0 ] || die "no external output connected, refusing to blank $PANEL"
    place row "${ext[@]}"
    swaymsg output "$PANEL" disable >/dev/null
    notify "External only: ${ext[*]}"
}

off() {
    local n="${1:-}"
    [ -n "$n" ] || die "usage: $0 off <output>"
    has "$n" || die "no such output: $n"
    if [ "$(count_active)" -le 1 ] && active_names | grep -qx "$n"; then
        die "$n is the only active output, refusing to leave you with a dark screen"
    fi
    swaymsg output "$n" disable >/dev/null
    notify "Off: $n"
}

on() {
    local n="${1:-}"
    [ -n "$n" ] || die "usage: $0 on <output>"
    has "$n" || die "no such output: $n"
    swaymsg output "$n" enable >/dev/null
    notify "On: $n"
}

list() {
    outputs | jq -r '.[] |
        "\(.name)\t\(if .active then "on " else "off" end)\t\(.rect.width)x\(.rect.height)+\(.rect.x)+\(.rect.y)\tscale \(.scale)\t\(.make) \(.model)"' |
        column -t -s $'\t'
}

menu() {
    command -v wofi >/dev/null || die "wofi is not installed"
    local -a items=(
        "Extend right"
        "Extend left"
        "Extend above"
        "Internal only"
        "External only"
    )
    local n
    for n in $(active_names); do
        [ "$n" = "$PANEL" ] && continue
        items+=("Turn off $n")
    done
    for n in $(external_names); do
        active_names | grep -qx "$n" || items+=("Turn on $n")
    done
    command -v wdisplays >/dev/null && items+=("Open wdisplays")

    local pick
    pick="$(printf '%s\n' "${items[@]}" | wofi --dmenu --prompt Displays)" || exit 0
    case "$pick" in
        "Extend right")  extend right ;;
        "Extend left")   extend left ;;
        "Extend above")  extend up ;;
        "Internal only") internal_only ;;
        "External only") external_only ;;
        "Turn off "*)    off "${pick#Turn off }" ;;
        "Turn on "*)     on "${pick#Turn on }" ;;
        "Open wdisplays") wdisplays & ;;
    esac
}

usage() {
    cat <<USAGE
usage: $0 <command>

  extend [right|left|up|down] [OUTPUT]  place the external(s) next to $PANEL
  internal-only                         only $PANEL, externals off
  external-only                         only the external(s), $PANEL off
  off OUTPUT                            disable one output
  on OUTPUT                             enable one output
  list                                  show every connected output
  menu                                  wofi picker (bound to Mod+p)

The internal panel is $PANEL; override with SWAY_PANEL_OUTPUT.
USAGE
}

case "${1:-menu}" in
    extend)        shift; extend "$@" ;;
    internal-only) internal_only ;;
    external-only) external_only ;;
    off)           shift; off "$@" ;;
    on)            shift; on "$@" ;;
    list)          list ;;
    menu)          menu ;;
    -h|--help|help) usage ;;
    *)             usage >&2; exit 2 ;;
esac
