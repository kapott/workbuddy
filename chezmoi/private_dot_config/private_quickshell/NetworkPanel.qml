pragma Singleton

// Rows for the network panel: the Wi-Fi switch, then every network the radio
// sees, connected first and then by signal. Enter on a known or open network
// connects, on the connected one disconnects. A new secured network opens
// `nmtui connect <ssid>` in kitty, which asks for the password; this shell has
// no secret prompt of its own.
//
// The radio only scans while this panel is open.
//
//   bindsym $mod+Ctrl+w nop qs menu toggle network

import QtQuick
import Quickshell
import Quickshell.Networking

Singleton {
    id: root

    readonly property string title: "Network"
    readonly property var wifi: [...Networking.devices.values].find(device => device.type === DeviceType.Wifi) ?? null
    // Set by Menu.qml while this panel is on screen.
    property bool showing: false

    readonly property var networks: root.wifi ? [...root.wifi.networks.values]
        .sort((a, b) => (b.connected - a.connected) || (b.signalStrength - a.signalStrength)) : []

    Binding {
        when: root.wifi !== null
        target: root.wifi
        property: "scannerEnabled"
        value: root.showing
    }

    // signalStrength is 0 to 1; see NetworkStatus.qml.
    function percent(network) {
        return Math.round(network.signalStrength * 100);
    }

    function statusOf(network) {
        const state = network.connected ? "connected"
            : network.state === ConnectionState.Connecting ? "connecting"
            : network.known ? "saved"
            : network.security === WifiSecurityType.Open ? "open"
            : "secured";
        return state + " · " + root.percent(network) + "%";
    }

    function rowFor(network) {
        const needsSecret = !network.known && network.security !== WifiSecurityType.Open;
        return {
            label: network.name,
            sub: root.statusOf(network),
            glyph: Glyph.wifi(root.percent(network)),
            on: network.connected,
            close: needsSecret,
            act: () => network.connected ? network.disconnect()
                : needsSecret ? Quickshell.execDetached(["kitty", "-e", "nmtui", "connect", network.name])
                : network.connect()
        };
    }

    readonly property var items: [
        { label: "Wi-Fi", icon: "wifiOn", on: Networking.wifiEnabled,
          act: () => Networking.wifiEnabled = !Networking.wifiEnabled },
        ...root.networks.map(root.rowFor),
        { label: "Connections", sub: "nmtui", icon: "cog", sh: "kitty -e nmtui" }
    ]
}
