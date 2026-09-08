// Memory in use, counted the way free(1) does it: total minus MemAvailable, not
// total minus MemFree. MemFree ignores reclaimable page cache and would report
// this machine at 90% while nothing is under pressure.

import QtQuick
import Quickshell.Io

Pill {
    id: root

    property real usedGb: 0
    property real totalGb: 0

    readonly property int percent: root.totalGb > 0 ? Math.round(root.usedGb * 100 / root.totalGb) : 0

    icon: Glyph.memory
    label: root.percent + "%"
    tint: Theme.yellow
    tooltip: root.usedGb.toFixed(1) + "G of " + root.totalGb.toFixed(1) + "G"

    FileView {
        id: meminfo
        path: "/proc/meminfo"
        preload: true

        onLoaded: {
            const kb = {};
            for (const line of this.text().split("\n")) {
                const match = /^(\w+):\s+(\d+) kB/.exec(line);
                if (match)
                    kb[match[1]] = parseInt(match[2], 10);
            }
            if (!kb.MemTotal)
                return;

            root.totalGb = kb.MemTotal / 1048576;
            root.usedGb = (kb.MemTotal - (kb.MemAvailable ?? kb.MemFree)) / 1048576;
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: meminfo.reload()
    }
}
