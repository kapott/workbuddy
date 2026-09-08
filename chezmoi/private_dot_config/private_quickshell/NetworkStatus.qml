// Wi-Fi or wired, whichever is actually carrying traffic.
//
// Quickshell.Networking talks to NetworkManager, which is what nm-applet in the
// tray is already driving, so the two never disagree. The wired device wins when
// both are up, matching how the routing table will actually behave.

import QtQuick
import Quickshell
import Quickshell.Networking

Pill {
    id: root

    readonly property var devices: [...Networking.devices.values]
    readonly property var wired: root.devices.find(d => d.type === DeviceType.Wired && d.connected) ?? null
    readonly property var wifi: root.devices.find(d => d.type === DeviceType.Wifi && d.connected) ?? null
    readonly property var wifiNetwork: root.wifi
        ? [...root.wifi.networks.values].find(n => n.connected) ?? null
        : null

    icon: root.wired ? Glyph.ethernet
        : root.wifiNetwork ? Glyph.wifi(root.wifiNetwork.signalStrength)
        : root.wifi ? Glyph.wifiOff
        : Glyph.lanDisconnect
    label: root.wired ? "" : (root.wifiNetwork ? root.wifiNetwork.name : "")
    tint: root.wired || root.wifiNetwork ? Theme.cyan : Theme.dim
    tooltip: root.wired ? root.wired.name + " " + root.wired.address
        : root.wifiNetwork ? root.wifiNetwork.name + " " + Math.round(root.wifiNetwork.signalStrength) + "%\n" + root.wifi.address
        : "Disconnected"

    onClicked: mouse => {
        if (mouse.button === Qt.RightButton)
            Quickshell.execDetached(["kitty", "-e", "nmtui"]);
    }
}
