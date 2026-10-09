pragma Singleton

// The Monokai-ish palette waybar's style.css carried, in one place. sway's
// borders, mako and swaylock use the same colours; changing one means changing
// all four.

import QtQuick
import Quickshell

Singleton {
    readonly property color background: "#282a2e"
    readonly property color raised: "#373b41"
    readonly property color foreground: "#c5c8c6"
    readonly property color dim: "#707880"
    readonly property color yellow: "#f0c674"
    readonly property color cyan: "#8abeb7"
    readonly property color green: "#a6e3a1"
    readonly property color amber: "#f9e2af"
    readonly property color red: "#a54242"
    readonly property color orange: "#fd971f"

    readonly property string fontFamily: "Hack Nerd Font Mono"
    readonly property int fontSize: 14
    readonly property int iconSize: 16

    readonly property int barHeight: 30
    readonly property int gap: 4
    readonly property int padding: 10
    readonly property int accentHeight: 3

    // The clock overlay $mod+t raises. osdDuration is the floor under a tap and
    // osdHoldLimit the ceiling over a hold, both in milliseconds.
    readonly property int osdFontSize: 128
    readonly property int osdSubFontSize: 26
    readonly property int osdSubGap: 10
    readonly property int osdPadding: 40
    readonly property int osdRadius: 12
    readonly property int osdDuration: 1000
    readonly property int osdHoldLimit: 60000

    // The level bar the volume, brightness and keyboard light keys raise.
    readonly property int osdLevelWidth: 320
    readonly property int osdLevelHeight: 56
    readonly property int osdLevelMargin: 120
    readonly property int osdLevelLabelWidth: 80
    readonly property int osdLevelDuration: 1200

    // Notification popups, sized like mako's config had them.
    readonly property int notificationWidth: 300
    readonly property int notificationMaxVisible: 5
    readonly property int notificationImageSize: 48
    readonly property int notificationBodyLines: 4

    // The menu $mod+space opens, and the panels that share its frame.
    readonly property color scrim: Qt.rgba(0, 0, 0, 0.35)
    readonly property int menuWidth: 560
    readonly property int menuRowHeight: 36
    readonly property int menuMaxRows: 14
    readonly property int menuRadius: 8
    readonly property int menuIconSize: 22
}
