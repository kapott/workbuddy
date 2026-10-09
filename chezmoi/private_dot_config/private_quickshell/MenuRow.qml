// One row of the menu: an icon, the label, a dim second column, and on the
// right a chevron for a submenu or a check for a switch that is on. A reading
// (info) is dim all over, since Enter does nothing on it.
//
// An app row draws its theme icon; every other row draws a Glyph by name.

import QtQuick
import Quickshell
import Quickshell.Widgets

Rectangle {
    id: row

    required property var modelData
    required property int index
    property bool selected: false
    property bool armed: false

    signal hovered()
    signal chosen()

    readonly property bool isApp: !!row.modelData.entry
    // Empty when the icon theme has nothing under the entry's Icon= name; the
    // row then falls back to a glyph rather than a blank square.
    readonly property string appIcon: row.isApp && row.modelData.entry.icon ? Quickshell.iconPath(row.modelData.entry.icon, true) : ""
    readonly property bool switchedOn: row.modelData.on === true
        || (!!row.modelData.state && ShellState[row.modelData.state] === true)

    height: Theme.menuRowHeight
    radius: 4
    color: row.selected ? Theme.raised : "transparent"

    Item {
        id: icon
        x: Theme.padding
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.menuIconSize
        height: Theme.menuIconSize

        IconImage {
            visible: row.appIcon !== ""
            anchors.fill: parent
            source: row.appIcon
        }

        Text {
            visible: row.appIcon === ""
            anchors.centerIn: parent
            text: row.isApp ? Glyph.apps : row.modelData.glyph ?? Glyph[row.modelData.icon] ?? ""
            color: row.armed ? Theme.orange : row.isApp ? Theme.dim : Theme.yellow
            font.family: Theme.fontFamily
            font.pixelSize: Theme.iconSize
        }
    }

    // Capped so a long device name stops short of the check on the right
    // instead of running under it.
    Text {
        id: label
        anchors.left: icon.right
        anchors.leftMargin: Theme.padding
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(implicitWidth, row.width - x - marker.width - Theme.padding * 3)
        elide: Text.ElideRight
        text: row.armed ? row.modelData.label + "? Enter to confirm" : row.modelData.label
        color: row.armed ? Theme.orange : row.modelData.info ? Theme.dim : Theme.foreground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
    }

    Text {
        anchors.left: label.right
        anchors.leftMargin: Theme.padding
        anchors.right: marker.left
        anchors.rightMargin: Theme.padding
        anchors.verticalCenter: parent.verticalCenter
        visible: !!row.modelData.sub
        text: row.modelData.sub ?? ""
        elide: Text.ElideRight
        color: Theme.dim
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize - 2
    }

    Text {
        id: marker
        anchors.right: parent.right
        anchors.rightMargin: Theme.padding
        anchors.verticalCenter: parent.verticalCenter
        text: row.modelData.menu ? Glyph.chevronRight : row.switchedOn ? Glyph.check : ""
        color: row.switchedOn ? Theme.green : Theme.dim
        font.family: Theme.fontFamily
        font.pixelSize: Theme.iconSize
    }

    // positionChanged rather than entered. A list that redraws under a still
    // pointer fires entered, which would steal the keyboard selection.
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onPositionChanged: row.hovered()
        onClicked: row.chosen()
    }
}
