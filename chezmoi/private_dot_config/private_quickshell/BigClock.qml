// The time, large, in the middle of the screen, for as long as $mod+t is held.
// sway calls over quickshell's IPC socket on both the press and the release;
// Osd.qml receives them.
//
// A tap still gets a full second. The release usually lands within a few dozen
// milliseconds of the press, and a flash that short is a flicker rather than a
// reading, so the minimum timer below outlives it.
//
// One of these per output, and only the output sway calls focused draws, so the
// clock does not flash on the external monitor as well. Matching is by name
// because I3.focusedMonitor and Quickshell.screens are different objects for the
// same physical output.

import QtQuick
import Quickshell
import Quickshell.I3
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var modelData
    screen: modelData

    // Anchoring to nothing is the whole of the positioning. Layer shell centres
    // a surface that anchors to no edge.
    visible: false
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-osd-clock"

    implicitWidth: face.implicitWidth + Theme.osdPadding * 2
    implicitHeight: face.implicitHeight + Theme.osdPadding * 2

    // An empty input region. Without it the surface swallows the click and the
    // hover of whatever it covers for the second it is up.
    mask: Region {}

    // Ticking only while the overlay is up. At Seconds precision this is a wake
    // every second, and the clock is visible for one of them per press.
    SystemClock {
        id: clock
        precision: SystemClock.Seconds
        enabled: root.visible
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.osdRadius
        color: Theme.background
        border.width: 1
        border.color: Theme.raised
    }

    // Everything below is derived from one Date and returns a string. Qt's
    // format strings cover the date itself but know nothing about ISO weeks or
    // quarters, so those two are counted here.
    function subtitle(date: date): string {
        return [
            Qt.formatDateTime(date, "ddd d MMM yyyy"),
            "week " + isoWeek(date),
            "Q" + quarterOf(date) + " (" + daysPhrase(daysLeftInQuarter(date)) + ")"
        ].join("  \u00b7  ");
    }

    // ISO 8601: the week is the one holding its Thursday, and week 1 is the one
    // holding 4 January. Shifting both to their Thursday makes the subtraction
    // exact, which is why 4 January is used rather than 1 January.
    function isoWeek(date: date): int {
        const thisThursday = thursdayOf(date);
        const firstThursday = thursdayOf(new Date(thisThursday.getFullYear(), 0, 4));
        return 1 + Math.round(dayspan(firstThursday, thisThursday) / 7);
    }

    function thursdayOf(date: date): date {
        const d = midnight(date);
        d.setDate(d.getDate() + 3 - (d.getDay() + 6) % 7);
        return d;
    }

    function quarterOf(date: date): int {
        return Math.floor(date.getMonth() / 3) + 1;
    }

    // Today counts as a day the quarter still has, so the last day of September
    // reads "1 day left" rather than "0".
    function daysLeftInQuarter(date: date): int {
        const nextQuarter = new Date(date.getFullYear(), quarterOf(date) * 3, 1);
        return dayspan(midnight(date), nextQuarter);
    }

    function midnight(date: date): date {
        return new Date(date.getFullYear(), date.getMonth(), date.getDate());
    }

    // Rounding, not truncating: a DST switch inside the span makes it 23 or 25
    // hours short of a whole number of days.
    function dayspan(from: date, to: date): int {
        return Math.round((to - from) / 86400000);
    }

    function daysPhrase(days: int): string {
        return days === 1 ? "1 day left" : days + " days left";
    }

    Column {
        id: face
        anchors.centerIn: parent
        spacing: Theme.osdSubGap

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "HH:mm:ss")
            color: Theme.yellow
            font.family: Theme.fontFamily
            font.pixelSize: Theme.osdFontSize
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.subtitle(clock.date)
            color: Theme.foreground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.osdSubFontSize
        }
    }

    // The key is down. Only the overlay that answered the press sets it, so the
    // release can clear it on every screen without having to ask sway again
    // which output was focused.
    property bool held: false

    // The floor under a tap. While it runs the clock stays up whatever the key
    // does, and releasing during it hands the hiding over to onTriggered.
    Timer {
        id: minimum
        interval: Theme.osdDuration
        onTriggered: if (!root.held) root.visible = false
    }

    // Nothing is held for a minute, so reaching this means the release was
    // lost: sway reloaded mid-press, or the binding never fired. Without it the
    // overlay would sit over the screen until quickshell restarts.
    Timer {
        id: stuck
        interval: Theme.osdHoldLimit
        onTriggered: root.dismiss()
    }

    function dismiss(): void {
        held = false;
        stuck.stop();
        if (!minimum.running)
            visible = false;
    }

    Connections {
        target: Osd

        function onClockRequested(): void {
            const focused = I3.focusedMonitor;
            if (focused && focused.name !== root.modelData.name)
                return;

            root.held = true;
            root.visible = true;
            // restart(), not start(): a second press while the clock is up
            // should give it another full second, not let the first timer end it.
            minimum.restart();
            stuck.restart();
        }

        function onClockReleased(): void {
            root.dismiss();
        }
    }
}
