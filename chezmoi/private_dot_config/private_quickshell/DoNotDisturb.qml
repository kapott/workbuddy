// A sleeping bell while do not disturb is on, nothing otherwise. Popups stop
// silently under DND, so without a sign it is easy to forget it is on.
// Left click turns it off, right click opens the history.

import QtQuick

Pill {
    visible: ShellState.doNotDisturb
    icon: Glyph.bellSleep
    tint: Theme.orange
    tooltip: "Do not disturb: popups held back, history still kept"

    onClicked: mouse => {
        if (mouse.button === Qt.RightButton)
            Menu.toggle("notifications");
        else
            ShellState.toggle("doNotDisturb");
    }
}
