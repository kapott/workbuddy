// The popup column in the top right of the focused output, newest on top,
// mako's layout: 300px cards, at most five, under the bar.
//
// The window is exactly as tall as the cards, so nothing beside or below them
// catches a click.

import QtQuick
import Quickshell
import Quickshell.I3
import Quickshell.Wayland

PanelWindow {
    id: root

    readonly property var shown: Notifications.popups.slice(0, Theme.notificationMaxVisible)

    // Follows focus when a new popup arrives, not while one is up, so a card
    // does not jump outputs under the pointer that is about to click it.
    property var target: Quickshell.screens[0]
    screen: root.target

    Connections {
        target: Notifications

        function onPopupsChanged() {
            if (Notifications.popups.length === 0)
                return;
            const name = I3.focusedMonitor?.name;
            root.target = Quickshell.screens.find(s => s.name === name) ?? root.target;
        }
    }

    visible: root.shown.length > 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-notifications"
    exclusiveZone: 0
    anchors.top: true
    anchors.right: true
    margins.top: Theme.gap * 2
    margins.right: Theme.gap * 2
    implicitWidth: Theme.notificationWidth
    implicitHeight: Math.max(1, column.implicitHeight)

    Column {
        id: column
        width: parent.width
        spacing: Theme.gap * 2

        Repeater {
            model: root.shown

            NotificationCard {
                width: column.width
            }
        }
    }
}
