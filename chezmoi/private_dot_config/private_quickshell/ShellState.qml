pragma Singleton

// Switches that more than one part of the shell reads. The bar module, the
// toggle menu and a key binding all flip the same idle inhibitor. One object,
// changed only through toggle(), so there is a single place to look when a
// switch is in the wrong position.
//
//   qs ipc call state toggle idleInhibited
//   bindsym ... nop qs state toggle barVisible

import QtQuick
import Quickshell

Singleton {
    id: root

    // Each Bar holds an IdleInhibitor bound to this. A Wayland inhibitor has to
    // belong to a surface, and the bar is the one surface that is always up.
    property bool idleInhibited: false
    property bool barVisible: true
    property bool doNotDisturb: false

    readonly property var switches: ["idleInhibited", "barVisible", "doNotDisturb"]

    function toggle(name: string): void {
        if (!root.switches.includes(name)) {
            console.warn("state: no switch " + name);
            return;
        }
        root[name] = !root[name];
    }

    Ipc {
        target: "state"

        function toggle(name: string): void {
            root.toggle(name);
        }
    }
}
