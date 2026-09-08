// The binding mode, shown only while one is active. sway is in "default" almost
// all the time; the one mode this config defines is resize, on Mod+r.
//
// The I3 singleton subscribes to workspace and output events on its own. Mode is
// not one of them, so this listener adds the subscription and parses the event
// body itself.

import QtQuick
import QtQuick.Layouts
import Quickshell.I3

Item {
    id: root

    property string mode: "default"

    visible: root.mode !== "default"
    implicitWidth: visible ? label.implicitWidth + Theme.padding * 2 : 0
    implicitHeight: Theme.barHeight
    Layout.preferredHeight: Theme.barHeight

    I3IpcListener {
        subscriptions: ["mode"]

        onIpcEvent: event => {
            if (event.type !== "mode")
                return;
            root.mode = JSON.parse(event.data).change;
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.raised
    }

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: Theme.accentHeight
        color: Theme.yellow
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.mode
        color: Theme.foreground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.italic: true
    }
}
