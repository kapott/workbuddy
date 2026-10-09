// A level bar near the bottom of the focused output: an icon, a fill, and the
// number. Up for osdLevelDuration after the last change, so holding a volume
// key keeps it up and lets go once the key does.
//
// One window that moves to whichever output sway calls focused when a level
// arrives, rather than one per screen like BigClock, because nothing here has
// to survive a press and a release landing on different outputs.

import QtQuick
import Quickshell
import Quickshell.I3
import Quickshell.Wayland

PanelWindow {
    id: root

    property string icon
    property real fraction
    property string label

    visible: false
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-osd-level"
    anchors.bottom: true
    margins.bottom: Theme.osdLevelMargin
    implicitWidth: Theme.osdLevelWidth
    implicitHeight: Theme.osdLevelHeight

    // An empty input region, as in BigClock, so the bar does not eat clicks.
    mask: Region {}

    Connections {
        target: Osd

        function onLevelShown(icon, fraction, label) {
            const name = I3.focusedMonitor?.name;
            root.screen = Quickshell.screens.find(s => s.name === name) ?? Quickshell.screens[0];
            root.icon = icon;
            root.fraction = Math.max(0, Math.min(1, fraction));
            root.label = label;
            root.visible = true;
            hide.restart();
        }
    }

    Timer {
        id: hide
        interval: Theme.osdLevelDuration
        onTriggered: root.visible = false
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.osdRadius
        color: Theme.background
        border.width: 1
        border.color: Theme.raised

        Text {
            id: glyph
            x: Theme.padding * 1.5
            anchors.verticalCenter: parent.verticalCenter
            text: root.icon
            color: Theme.yellow
            font.family: Theme.fontFamily
            font.pixelSize: Theme.menuIconSize
        }

        Rectangle {
            id: track
            anchors.left: glyph.right
            anchors.leftMargin: Theme.padding
            anchors.right: number.left
            anchors.rightMargin: Theme.padding
            anchors.verticalCenter: parent.verticalCenter
            height: 6
            radius: 3
            color: Theme.raised

            Rectangle {
                width: parent.width * root.fraction
                height: parent.height
                radius: parent.radius
                color: Theme.yellow
            }
        }

        Text {
            id: number
            anchors.right: parent.right
            anchors.rightMargin: Theme.padding * 1.5
            anchors.verticalCenter: parent.verticalCenter
            width: Theme.osdLevelLabelWidth
            horizontalAlignment: Text.AlignRight
            text: root.label
            color: Theme.foreground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }
    }
}
