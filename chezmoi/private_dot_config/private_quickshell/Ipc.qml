// An IpcHandler a sway binding can reach as well. Declare functions on it the
// way an IpcHandler wants them, with typed arguments, and both of these call
// the same code:
//
//   qs ipc call menu toggle root          from a script or a terminal
//   bindsym $mod+space nop qs menu toggle root    from sway, no process started

import QtQml
import Quickshell.Io

IpcHandler {
    id: handler

    Component.onCompleted: IpcRegistry.register(handler)
    Component.onDestruction: IpcRegistry.unregister(handler)
}
