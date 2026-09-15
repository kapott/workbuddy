//@ pragma UseQApplication

// Quickshell replaces waybar here. One bar per output, so the workspace strip
// only lists workspaces that live on that output, the way waybar's
// "all-outputs": false did.
//
// UseQApplication is what lets tray items open their real DBus menus; with the
// plain QGuiApplication quickshell refuses and logs a hint instead.

import QtQml
import Quickshell
import Quickshell.I3

ShellRoot {
    // I3.focusedMonitor stays null until something asks sway for the monitor
    // list, and BigClock needs it on the first press. Workspaces triggers the
    // same sync as a side effect of reading I3.workspaces; asking here does not
    // depend on that. QtQml is imported for this line alone. Without it the
    // Component attached type does not exist and the shell fails to load.
    Component.onCompleted: I3.refreshMonitors()

    Variants {
        model: Quickshell.screens

        Bar {}
    }

    // Hidden until a key binding asks for it, so it costs a surface per screen
    // and nothing else.
    Variants {
        model: Quickshell.screens

        BigClock {}
    }
}
