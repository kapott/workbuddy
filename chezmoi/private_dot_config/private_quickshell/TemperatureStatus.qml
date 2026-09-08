// Package temperature from hwmon, in millidegrees.
//
// The path is a glob resolved once at startup: hwmon directories are numbered in
// probe order, so hardcoding hwmon6 works until a driver loads earlier and the
// module silently reads a different sensor.

import QtQuick
import Quickshell.Io

Pill {
    id: root

    property string path
    property int celsius: 0

    readonly property bool critical: root.celsius >= Host.temperatureCritical

    visible: root.path !== ""
    icon: root.critical ? Glyph.thermometerAlert : Glyph.thermometer
    label: root.celsius + "°"
    tint: root.critical ? Theme.red : Theme.cyan

    Process {
        running: true
        command: ["sh", "-c", "for f in " + Host.temperatureGlob + "; do [ -e \"$f\" ] && { printf %s \"$f\"; break; }; done"]
        stdout: StdioCollector {
            onStreamFinished: root.path = this.text.trim()
        }
    }

    FileView {
        id: sensor
        path: root.path
        preload: true
        onLoaded: root.celsius = Math.round(parseInt(this.text().trim(), 10) / 1000)
    }

    Timer {
        interval: 5000
        running: root.path !== ""
        repeat: true
        onTriggered: sensor.reload()
    }
}
