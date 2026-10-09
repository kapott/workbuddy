pragma Singleton

// Rows for the bluetooth panel: the adapter switch, a scan switch, then every
// device BlueZ knows, connected first. Enter connects or disconnects a paired
// device and pairs an unpaired one. Pairing that needs a PIN still wants
// blueman's agent, so blueman-manager stays the last row.
//
//   bindsym $mod+Ctrl+b nop qs menu toggle bluetooth

import Quickshell
import Quickshell.Bluetooth

Singleton {
    id: root

    readonly property string title: "Bluetooth"
    // Set by Menu.qml while this panel is on screen; unused here.
    property bool showing: false
    readonly property var adapter: Bluetooth.defaultAdapter

    readonly property var devices: [...Bluetooth.devices.values]
        .sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || root.nameOf(a).localeCompare(root.nameOf(b)))

    function nameOf(device) {
        return device.name || device.address;
    }

    function statusOf(device) {
        const battery = device.batteryAvailable ? " · " + Math.round(device.battery * 100) + "%" : "";
        const state = device.state === BluetoothDeviceState.Connecting ? "connecting"
            : device.state === BluetoothDeviceState.Disconnecting ? "disconnecting"
            : device.pairing ? "pairing"
            : device.connected ? "connected"
            : device.paired ? "paired"
            : "not paired";
        return state + battery;
    }

    function toggleDevice(device) {
        if (device.connected)
            device.disconnect();
        else if (device.paired)
            device.connect();
        else
            device.pair();
    }

    readonly property var adapterRows: !root.adapter ? [{ label: "No adapter", icon: "bluetoothOff", info: true }] : [
        { label: "Bluetooth", icon: "bluetooth", on: root.adapter.enabled,
          act: () => root.adapter.enabled = !root.adapter.enabled },
        { label: root.adapter.discovering ? "Scanning" : "Scan for devices", icon: "refresh", on: root.adapter.discovering,
          act: () => root.adapter.discovering = !root.adapter.discovering }
    ]

    readonly property var items: [
        ...root.adapterRows,
        ...root.devices.map(device => ({
            label: root.nameOf(device),
            sub: root.statusOf(device),
            icon: device.connected ? "bluetoothConnect" : "bluetooth",
            on: device.connected,
            act: () => root.toggleDevice(device)
        })),
        { label: "Bluetooth manager", sub: "blueman", icon: "tune", sh: "blueman-manager" }
    ]
}
