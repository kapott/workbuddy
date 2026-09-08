// Time, with the date on click. SystemClock at minute precision wakes on the
// minute boundary rather than on a timer that drifts a second at a time.

import QtQuick
import Quickshell

Pill {
    id: root

    property bool showDate: false

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    icon: Glyph.clock
    label: Qt.formatDateTime(clock.date, root.showDate ? "ddd yyyy-MM-dd HH:mm" : "HH:mm")
    tint: Theme.yellow
    tooltip: Qt.formatDateTime(clock.date, "dddd d MMMM yyyy")

    onClicked: root.showDate = !root.showDate
}
