pragma Singleton

// The one entry point for on-screen displays driven from a key binding.
// `qs ipc call osd clock` from sway lands on the handler below, which emits a
// signal every overlay listens to. The clock is held open while the key is
// down, so sway calls twice: `clock` on the press and `clockRelease` on the
// release.
//
// A singleton because there must be exactly one IpcHandler. Variants gives each
// screen its own overlay, and registering the same target once per screen makes
// quickshell refuse the duplicates.

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    signal clockRequested()
    signal clockReleased()

    IpcHandler {
        target: "osd"

        function clock(): void {
            root.clockRequested();
        }

        function clockRelease(): void {
            root.clockReleased();
        }
    }
}
