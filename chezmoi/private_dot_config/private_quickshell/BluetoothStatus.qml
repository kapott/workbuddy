// Bluetooth adapter state and how many devices are on it.

import QtQuick
import Quickshell
import Quickshell.Bluetooth

Pill {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var connected: adapter
        ? [...Bluetooth.devices.values].filter(d => d.connected)
        : []

    visible: root.adapter !== null
    icon: !root.adapter || !root.adapter.enabled ? Glyph.bluetoothOff
        : root.connected.length > 0 ? Glyph.bluetoothConnect
        : Glyph.bluetooth
    label: root.connected.length > 0 ? String(root.connected.length) : ""
    tint: !root.adapter || !root.adapter.enabled ? Theme.dim : Theme.cyan
    tooltip: root.connected.length > 0
        ? root.connected.map(d => d.name).join("\n")
        : "No device connected"

    onClicked: Quickshell.execDetached(["blueman-manager"])
}
