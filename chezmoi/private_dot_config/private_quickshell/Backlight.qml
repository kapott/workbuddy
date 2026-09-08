// Screen brightness, read from sysfs and written through brightnessctl.
//
// Writing to /sys/class/backlight directly needs root or a udev rule;
// brightnessctl ships one and is already a dependency, so the write goes through
// it while the read stays a plain file. sysfs does not raise inotify events for
// brightness, so the value is polled rather than watched, and re-read straight
// after our own scroll so the number moves with the wheel instead of a second
// later.

import QtQuick
import Quickshell
import Quickshell.Io

Pill {
    id: root

    property string dir
    property int value: 0
    property int max: 0

    readonly property int percent: root.max > 0 ? Math.round(root.value * 100 / root.max) : 0

    visible: root.max > 0
    icon: Glyph.brightness
    label: root.percent + "%"
    tint: Theme.yellow
    tooltip: root.dir === "" ? "" : root.dir.split("/").pop()

    // Host.backlightGlob is a glob because a machine can have several backlights
    // and endling's is one of two names AMD hands out depending on kernel.
    Process {
        running: true
        command: ["sh", "-c", "for d in " + Host.backlightGlob + "; do [ -e \"$d/brightness\" ] && { printf %s \"$d\"; break; }; done"]
        stdout: StdioCollector {
            onStreamFinished: root.dir = this.text.trim()
        }
    }

    FileView {
        id: brightness
        path: root.dir === "" ? "" : root.dir + "/brightness"
        preload: true
        onLoaded: root.value = parseInt(this.text().trim(), 10) || 0
    }

    FileView {
        id: maxBrightness
        path: root.dir === "" ? "" : root.dir + "/max_brightness"
        preload: true
        onLoaded: root.max = parseInt(this.text().trim(), 10) || 0
    }

    Timer {
        interval: 2000
        running: root.dir !== ""
        repeat: true
        triggeredOnStart: true
        onTriggered: brightness.reload()
    }

    function step(direction: int) {
        Quickshell.execDetached(["brightnessctl", "set", direction > 0 ? "+5%" : "5%-"]);
        refresh.restart();
    }

    // brightnessctl has to have written before the re-read is worth anything.
    Timer {
        id: refresh
        interval: 120
        onTriggered: brightness.reload()
    }

    onWheel: wheel => root.step(wheel.angleDelta.y)
}
