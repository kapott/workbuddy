// CPU load across all cores.
//
// /proc/stat counts jiffies since boot, so a single reading says nothing; the
// figure is the difference between two samples. The first tick therefore has no
// number to show and the indicator stays at 0 until the second.

import QtQuick
import Quickshell
import Quickshell.Io

Pill {
    id: root

    property int percent: 0
    property int lastBusy: 0
    property int lastTotal: 0

    icon: Glyph.cpu
    label: root.percent + "%"
    tint: Theme.yellow
    tooltip: "Click for btop"

    FileView {
        id: stat
        path: "/proc/stat"
        preload: true

        onLoaded: {
            // "cpu  user nice system idle iowait irq softirq steal ..."
            const fields = this.text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
            const total = fields.reduce((a, b) => a + b, 0);
            const busy = total - fields[3] - (fields[4] ?? 0);

            if (root.lastTotal > 0 && total > root.lastTotal) {
                root.percent = Math.round((busy - root.lastBusy) * 100 / (total - root.lastTotal));
            }

            root.lastBusy = busy;
            root.lastTotal = total;
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: stat.reload()
    }

    onClicked: Quickshell.execDetached(["kitty", "-e", "btop"])
}
