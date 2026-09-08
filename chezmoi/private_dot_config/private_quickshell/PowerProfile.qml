// The asusd power profile on the Z13. Hidden everywhere else.
//
// asusd and power-profiles-daemon both write the same three states under
// different names and whichever writes last wins, so this speaks only asusctl,
// through the same power-profile.sh the ROG fan key runs. The script writes the
// active profile to a state file after every change, which is how a press of the
// fan key repaints the bar without quickshell knowing the key exists.
//
// The 30s poll is still needed on top of the file watch: asusd switches profiles
// by itself when the power source changes, and nothing runs the script then.

import QtQuick
import Quickshell
import Quickshell.Io

Pill {
    id: root

    readonly property string script: Quickshell.env("HOME") + "/.config/sway/power-profile.sh"

    // Active, what asusd uses on AC, what it uses on battery.
    property string profile: ""
    property string onAc: ""
    property string onBattery: ""

    visible: Host.asusProfile
    icon: root.profile === "Performance" ? Glyph.speedometer
        : root.profile === "Balanced" ? Glyph.speedometerMedium
        : root.profile === "Quiet" ? Glyph.leaf
        : Glyph.unknown
    tint: root.profile === "Performance" ? Theme.red
        : root.profile === "Balanced" ? Theme.yellow
        : root.profile === "Quiet" ? Theme.cyan
        : Theme.dim
    tooltip: "Active: " + (root.profile || "unknown")
        + "\nOn AC: " + (root.onAc || "unknown")
        + "\nOn battery: " + (root.onBattery || "unknown")
        + "\nClick to cycle, right-click for the control centre"

    FileView {
        id: state
        path: Quickshell.env("XDG_RUNTIME_DIR") + "/power-profile"
        preload: true
        watchChanges: true
        printErrors: false

        onLoaded: {
            const lines = this.text().split("\n");
            root.profile = (lines[0] ?? "").trim();
            root.onAc = (lines[1] ?? "").trim();
            root.onBattery = (lines[2] ?? "").trim();
        }
        onFileChanged: this.reload()
    }

    // Reloading on exit rather than leaving it to watchChanges: on the first run
    // of a session the state file does not exist yet, and there is nothing for
    // inotify to watch until something creates it.
    Process {
        id: publish
        running: Host.asusProfile
        command: [root.script, "publish"]
        onExited: state.reload()
    }

    Timer {
        interval: 30000
        running: Host.asusProfile
        repeat: true
        onTriggered: publish.running = true
    }

    onClicked: mouse => {
        if (mouse.button === Qt.RightButton)
            Quickshell.execDetached(["rog-control-center"]);
        else
            Quickshell.execDetached([root.script, "next"]);
    }
}
