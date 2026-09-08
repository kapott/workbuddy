// The workspace strip for one output. Quickshell.I3 speaks sway's IPC as well
// as i3's, so this is the same socket swaymsg uses.

import QtQuick
import Quickshell
import Quickshell.I3

Row {
    id: root

    required property string screenName

    spacing: 0

    Repeater {
        model: ScriptModel {
            // I3.workspaces holds every output's workspaces. Filtering here is
            // what makes the bar on the laptop panel show 1-5 while the bar on
            // the external shows 6-10, which is waybar's "all-outputs": false.
            values: [...I3.workspaces.values]
                .filter(ws => ws.monitor && ws.monitor.name === root.screenName)
                .sort((a, b) => a.num - b.num)
        }

        delegate: MouseArea {
            id: workspace

            required property var modelData

            implicitWidth: name.implicitWidth + Theme.padding * 2
            implicitHeight: Theme.barHeight

            hoverEnabled: true
            onClicked: workspace.modelData.activate()

            Rectangle {
                anchors.fill: parent
                color: workspace.modelData.urgent ? Theme.red
                    : workspace.modelData.focused ? Theme.raised
                    : workspace.containsMouse ? Qt.rgba(0, 0, 0, 0.2)
                    : "transparent"
            }

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: Theme.accentHeight
                color: workspace.modelData.focused ? Theme.yellow : "transparent"
            }

            Text {
                id: name
                anchors.centerIn: parent
                text: workspace.modelData.name
                color: Theme.foreground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
            }
        }
    }
}
