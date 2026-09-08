//@ pragma UseQApplication

// Quickshell replaces waybar here. One bar per output, so the workspace strip
// only lists workspaces that live on that output, the way waybar's
// "all-outputs": false did.
//
// UseQApplication is what lets tray items open their real DBus menus; with the
// plain QGuiApplication quickshell refuses and logs a hint instead.

import Quickshell

ShellRoot {
    Variants {
        model: Quickshell.screens

        Bar {}
    }
}
