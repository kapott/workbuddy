// One right-hand module: an icon, an optional reading next to it, and a click
// target around both. Everything from the volume indicator to the clock is one
// of these, so spacing and hit area stay identical across the bar.

import QtQuick
import QtQuick.Layouts

MouseArea {
    id: root

    property string icon
    property string label
    property color tint: Theme.foreground
    property string tooltip

    implicitWidth: content.implicitWidth + Theme.padding * 2
    implicitHeight: Theme.barHeight
    Layout.preferredHeight: Theme.barHeight

    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    hoverEnabled: true

    Tooltip {
        target: root
        text: root.tooltip
        active: root.containsMouse
    }

    Row {
        id: content
        anchors.centerIn: parent
        spacing: 6

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.icon
            color: root.tint
            font.family: Theme.fontFamily
            font.pixelSize: Theme.iconSize
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.label !== ""
            text: root.label
            color: root.tint
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }
    }
}
