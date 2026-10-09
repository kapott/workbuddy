pragma Singleton

// The one entry point for on-screen displays driven from a key binding.
// sway binds the key to `nop qs osd clock`, which runs nothing but announces
// the binding on sway's IPC socket. The listener below matches the command and
// emits a signal every overlay listens to. No process starts per keypress:
// measured 2026-10-09 at 2.0 ms from key to handler, against 19 ms for
// `exec qs ipc call`. The clock is held open while the key is down, so sway
// fires twice: `clock` on the press and `clockRelease` on the release.
//
// The IpcHandler stays for scripts and the shell: `qs ipc call osd clock`.
//
// A singleton because there must be exactly one IpcHandler. Variants gives each
// screen its own overlay, and registering the same target once per screen makes
// quickshell refuse the duplicates.

import Quickshell
import Quickshell.I3
import Quickshell.Io

Singleton {
    id: root

    signal clockRequested()
    signal clockReleased()

    readonly property var bindings: ({
        "nop qs osd clock": root.clockRequested,
        "nop qs osd clockRelease": root.clockReleased
    })

    I3IpcListener {
        subscriptions: ["binding"]

        onIpcEvent: event => {
            const binding = JSON.parse(event.data).binding;
            const action = binding ? root.bindings[binding.command] : undefined;
            if (action)
                action();
        }
    }

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
