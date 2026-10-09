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

    // Hidden is one transparent pixel with no exclusive zone. Unmapping the
    // surface would end the idle inhibitor below, which belongs to it.
    color: ShellState.barVisible ? Theme.background : "transparent"
    implicitHeight: ShellState.barVisible ? Theme.barHeight : 1
    exclusiveZone: ShellState.barVisible ? Theme.barHeight : 0

    anchors {
        top: true
        left: true
        right: true
    }

    // Held by the bar rather than by the indicator, so the inhibitor survives
    // the indicator being restyled or moved. Its switch is in ShellState, where
    // the toggle menu flips it too.
    IdleInhibitor {
        window: bar
        enabled: ShellState.idleInhibited
    }

    RowLayout {
        visible: ShellState.barVisible
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

        DoNotDisturb {}
        IdleInhibit {}
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
