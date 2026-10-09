pragma Singleton

// Turns sway key bindings into Ipc calls without starting a process.
//
// A binding written as `bindsym <keys> nop qs <target> <method> [arg ...]` runs
// nothing in sway, but sway still sends the binding event to every IPC
// subscriber, command text included. This listener parses that text and hands
// it to IpcRegistry. Measured on endling 2026-10-09, 100 presses, median key to
// handler: nop 2.0 ms, `exec qs ipc call` 19.0 ms, because the latter starts a
// whole Qt client per press.
//
// Arguments are split on spaces and cannot hold one. sway also strips quotes
// and backslashes from a binding before it reports it, so quoting does not help.
//
// shell.qml touches this singleton at startup, because a QML singleton only
// exists once something reads it. A press in the first moment after quickshell
// starts is lost before the subscription is up.

import Quickshell
import Quickshell.I3

Singleton {
    id: root

    readonly property string prefix: "nop qs "

    function parse(command) {
        if (!command || !command.startsWith(root.prefix))
            return null;
        const [target, method, ...args] = command.slice(root.prefix.length).trim().split(/\s+/);
        return method ? { target, method, args } : null;
    }

    I3IpcListener {
        subscriptions: ["binding"]

        onIpcEvent: event => {
            const binding = JSON.parse(event.data).binding;
            const call = root.parse(binding?.command);
            if (call)
                IpcRegistry.call(call.target, call.method, call.args);
        }
    }
}
