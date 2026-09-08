// The bar itself. Left to right: workspaces, the binding mode when one is
// active, the focused window, then the indicators pushed against the right
// edge by the title's fillWidth.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: bar

    required property var modelData
    screen: modelData

    color: Theme.background
    implicitHeight: Theme.barHeight

    anchors {
        top: true
        left: true
        right: true
    }

    // Held by the shell rather than by the indicator, so the inhibitor survives
    // the indicator being restyled or moved.
    IdleInhibitor {
        id: idleInhibitor
        window: bar
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.gap
        anchors.rightMargin: Theme.gap
        spacing: Theme.gap

        Workspaces {
            screenName: bar.modelData.name
            Layout.fillHeight: true
        }

        SwayMode {}

        WindowTitle {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        IdleInhibit { inhibitor: idleInhibitor }
        Volume {}
        Backlight {}
        BluetoothStatus {}
        NetworkStatus {}
        CpuUsage {}
        MemoryUsage {}
        TemperatureStatus {}
        PowerProfile {}
        BatteryStatus {}
        Clock {}
        Tray {}
    }
}
