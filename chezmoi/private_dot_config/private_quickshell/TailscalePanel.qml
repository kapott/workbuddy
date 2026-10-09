pragma Singleton

// Rows for the tailscale panel: the up/down switch, the exit node choice, then
// every peer, online first. Enter on a peer copies its first tailnet IP.
//
// There is no D-Bus API, so this reads `tailscale status --json` on open and
// every few seconds while the panel is on screen. The CLI works without sudo
// because the tailnet's OperatorUser is set to this user (`tailscale debug
// prefs`); without that, up, down and set fail and the error is shown as a
// notification.
//
//   bindsym $mod+Ctrl+t nop qs menu toggle tailscale

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string title: "Tailscale"
    readonly property int pollMs: 4000
    // Set by Menu.qml while this panel is on screen.
    property bool showing: false

    property var status: null
    // False until the first read finishes. The first `tailscale status` after
    // login takes over a second, and "not answering" before it has answered
    // would be a lie.
    property bool loaded: false

    readonly property bool running: root.status?.BackendState === "Running"
    readonly property var peers: Object.values(root.status?.Peer ?? {})
        .sort((a, b) => (b.Online - a.Online) || root.hostOf(a).localeCompare(root.hostOf(b)))
    readonly property var exitNodes: root.peers.filter(peer => peer.ExitNodeOption)
    readonly property var activeExit: root.peers.find(peer => peer.ExitNode) ?? null

    function hostOf(peer) {
        return (peer.DNSName || "").split(".")[0] || peer.HostName;
    }

    function refresh() {
        statusProcess.running = true;
    }

    // Runs a tailscale subcommand, then reads the status again. A failure is a
    // notification with tailscale's own message, since the panel has no room
    // for one.
    function tailscale(args) {
        command.command = ["tailscale", ...args];
        command.running = true;
    }

    onShowingChanged: if (showing) root.refresh()

    Timer {
        interval: root.pollMs
        running: root.showing
        repeat: true
        onTriggered: root.refresh()
    }

    Process {
        id: statusProcess
        command: ["tailscale", "status", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.status = JSON.parse(this.text);
                } catch (e) {
                    root.status = null;
                }
                root.loaded = true;
            }
        }
    }

    Process {
        id: command
        stderr: StdioCollector {
            id: commandError
        }
        onExited: code => {
            if (code !== 0)
                Quickshell.execDetached(["notify-send", "Tailscale", commandError.text.trim() || "exit " + code]);
            root.refresh();
        }
    }

    readonly property var exitRows: root.exitNodes.length === 0 ? [] : [
        { label: "No exit node", icon: "vpn", on: root.activeExit === null, act: () => root.tailscale(["set", "--exit-node="]) },
        ...root.exitNodes.map(peer => ({
            label: "Exit via " + root.hostOf(peer),
            sub: peer.Online ? "online" : "offline",
            icon: "vpn",
            on: peer.ExitNode === true,
            act: () => root.tailscale(["set", "--exit-node=" + peer.TailscaleIPs[0]])
        }))
    ]

    readonly property var items: !root.loaded ? [{ label: "Reading tailscale status", icon: "vpn", info: true }]
        : root.status === null ? [{ label: "tailscaled not answering", icon: "vpn", info: true }] : [
        // Down asks for a second Enter, as in NetworkPanel.
        { label: "Tailscale", sub: root.status.BackendState, icon: "vpn", on: root.running, confirm: root.running,
          act: () => root.tailscale([root.running ? "down" : "up"]) },
        ...root.exitRows,
        ...root.peers.map(peer => ({
            label: root.hostOf(peer),
            sub: (peer.TailscaleIPs?.[0] ?? "") + (peer.Online ? "" : " · offline"),
            icon: "laptop",
            on: peer.Online === true,
            close: true,
            act: () => Quickshell.execDetached(["sh", "-c", 'printf %s "$1" | wl-copy && notify-send "Copied $1"', "sh", peer.TailscaleIPs?.[0] ?? ""])
        }))
    ]
}
