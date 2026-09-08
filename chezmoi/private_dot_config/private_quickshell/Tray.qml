// StatusNotifier tray. nm-applet and blueman-applet live here, so this is the
// one part of the bar whose contents this repo does not decide.
//
// item.display() hands the position to quickshell's own popup machinery, which
// is what makes a DBus menu land under the icon instead of at the pointer's last
// known place. It needs the UseQApplication pragma in shell.qml.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets

Rectangle {
    id: root

    visible: SystemTray.items.values.length > 0
    color: Theme.raised
    implicitWidth: icons.implicitWidth + Theme.padding * 2
    implicitHeight: Theme.barHeight
    Layout.preferredHeight: Theme.barHeight

    Row {
        id: icons
        anchors.centerIn: parent
        spacing: 10

        Repeater {
            model: SystemTray.items

            delegate: MouseArea {
                id: trayItem

                required property var modelData

                implicitWidth: Theme.iconSize
                implicitHeight: Theme.barHeight
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                hoverEnabled: true

                Tooltip {
                    target: trayItem
                    text: trayItem.modelData.tooltipTitle || trayItem.modelData.title
                    active: trayItem.containsMouse
                }

                IconImage {
                    anchors.centerIn: parent
                    implicitSize: Theme.iconSize
                    source: trayItem.modelData.icon
                    // Passive items are still registered but have nothing to
                    // say, so they dim rather than disappear.
                    opacity: trayItem.modelData.status === Status.Passive ? 0.5 : 1
                }

                onClicked: mouse => {
                    const item = trayItem.modelData;
                    if (mouse.button === Qt.LeftButton && !item.onlyMenu) {
                        item.activate();
                    } else if (mouse.button === Qt.MiddleButton) {
                        item.secondaryActivate();
                    } else if (item.hasMenu) {
                        item.display(QsWindow.window, trayItem.width / 2, trayItem.height);
                    }
                }
            }
        }
    }
}
