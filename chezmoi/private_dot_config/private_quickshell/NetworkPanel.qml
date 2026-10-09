pragma Singleton

// Rows for the network panel: the Wi-Fi switch, then every network the radio
// sees, connected first and then by signal. Enter on a known or open network
// connects, on the connected one disconnects. A new secured network asks for
// its password in the menu's own field and joins with connectWithPsk.
//
// That replaced `nmtui connect <ssid>`. NetworkManager leaves the current
// Wi-Fi the moment the attempt starts, so closing nmtui without a password
// left wlan0 off its network and a half-made profile behind (2026-10-09).
// Here a failed join is reported, its new profile forgotten and the network
// that was up before reconnected, so a wrong password costs a notification
// and nothing else.
//
// A wrong password does not always fail. NetworkManager asks a secret agent
// for a new one and waits, and on endling kded6 (plasma-nm) is such an agent:
// it opened its own password dialog and the join hung in "need
// authentication" with no connectionFailed. So a join that has not connected
// after joinTimeoutMs counts as failed too, which also withdraws that dialog.
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

    // The one join in flight, if any. Followed until it connects or fails and
    // then dropped, so a later outage on a network that joined fine can never
    // reach the forget() below.
    property var joining: null
    // The Wi-Fi network that was up when the join started, to go back to.
    property var previous: null
    readonly property int joinTimeoutMs: 20000

    function join(network, psk) {
        root.previous = root.networks.find(n => n.connected) ?? null;
        root.joining = network;
        joinTimer.restart();
        network.connectWithPsk(psk);
    }

    function failJoin(why) {
        const network = root.joining;
        root.joining = null;
        joinTimer.stop();
        root.notify("Could not join " + network.name, why);
        network.disconnect();
        network.forget();
        root.previous?.connect();
        root.previous = null;
    }

    Timer {
        id: joinTimer
        interval: root.joinTimeoutMs
        onTriggered: if (root.joining && !root.joining.connected) root.failJoin("No connection after " + root.joinTimeoutMs / 1000 + "s. Wrong password?")
    }

    function notify(summary, body) {
        Quickshell.execDetached(["notify-send", summary, body]);
    }

    Connections {
        target: root.joining

        function onConnectionFailed(reason) {
            root.failJoin(reason === ConnectionFailReason.NoSecrets || reason === ConnectionFailReason.WifiClientFailed
                || reason === ConnectionFailReason.WifiAuthTimeout ? "Wrong password?" : ConnectionFailReason.toString(reason));
        }

        function onConnectedChanged() {
            if (!root.joining?.connected)
                return;
            root.notify("Joined " + root.joining.name, "");
            root.joining = null;
            root.previous = null;
            joinTimer.stop();
        }
    }

    function rowFor(network) {
        const needsSecret = !network.known && network.security !== WifiSecurityType.Open;
        const row = {
            label: network.name,
            sub: root.statusOf(network),
            glyph: Glyph.wifi(root.percent(network)),
            on: network.connected
        };
        if (needsSecret)
            return Object.assign(row, { prompt: { label: "Password for " + network.name, submit: psk => root.join(network, psk) } });
        return Object.assign(row, { act: () => network.connected ? network.disconnect() : network.connect() });
    }

    readonly property var items: [
        // Switching off asks for a second Enter: this is the first row, and one
        // Enter too many after opening the panel would drop the connection.
        { label: "Wi-Fi", icon: "wifiOn", on: Networking.wifiEnabled, confirm: Networking.wifiEnabled,
          act: () => Networking.wifiEnabled = !Networking.wifiEnabled },
        ...root.networks.map(root.rowFor),
        { label: "Connections", sub: "nmtui", icon: "cog", sh: "kitty -e nmtui" }
    ]
}
