// A tooltip that can leave the bar.
//
// QtQuick.Controls' ToolTip cannot. A layer-shell surface is exactly 30px tall
// and a Controls popup is an item inside its own window, so the tip renders
// clipped to the bar and in the Fusion style's white-on-yellow rather than this
// palette. A quickshell PopupWindow is a real xdg_popup parented to the bar, so
// it draws over whatever is below.

import QtQuick
import Quickshell

PopupWindow {
    id: root

    required property Item target
    property string text
    /// Set while the pointer is over the target. The delay lives here so that
    /// crossing the bar does not flash a tip from every module on the way.
    property bool active: false

    visible: false
    color: "transparent"
    implicitWidth: label.implicitWidth + 16
    implicitHeight: label.implicitHeight + 10

    anchor.item: root.target
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom

    onActiveChanged: {
        if (root.active && root.text !== "") {
            delay.restart();
        } else {
            delay.stop();
            root.visible = false;
        }
    }

    Timer {
        id: delay
        interval: 400
        onTriggered: root.visible = true
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.raised
        border.color: Theme.dim
        border.width: 1

        Text {
            id: label
            anchors.centerIn: parent
            text: root.text
            color: Theme.foreground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
