pragma Singleton

// Every Ipc handler in the shell, so a sway binding can reach the same functions
// `qs ipc call` does. Bindings.qml hands it `target method args` parsed from a
// `nop qs ...` command; this finds the live handler for the target and runs the
// method, but only one the handler declares itself. QObject methods such as
// destroy() are callable from JS too, and a binding must not reach them.
//
// The idea is Omarchy's (shell/Commons/IpcRegistry.qml), where the same registry
// answers a socket instead of sway's binding events.

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var handlers: []

    // What a bare IpcHandler already has: signals, slots, property change
    // notifiers. Anything a handler adds beyond these is a declared function.
    readonly property var builtins: functionNames(bare)

    IpcHandler {
        id: bare
        enabled: false
    }

    function functionNames(object) {
        const names = [];
        for (const key in object) {
            if (typeof object[key] === "function")
                names.push(key);
        }
        return names;
    }

    function declared(handler) {
        return functionNames(handler).filter(name => !root.builtins.includes(name) && !name.endsWith("Changed"));
    }

    function register(handler) {
        if (!root.handlers.includes(handler))
            root.handlers.push(handler);
    }

    function unregister(handler) {
        root.handlers = root.handlers.filter(h => h !== handler);
    }

    function handlerFor(target) {
        return root.handlers.find(h => h && h.enabled && h.target === target) ?? null;
    }

    function call(target, method, args) {
        const handler = root.handlerFor(target);
        if (!handler || !root.declared(handler).includes(method)) {
            console.warn("binding: no " + target + "." + method);
            return;
        }
        if (handler[method].length !== args.length) {
            console.warn("binding: " + target + "." + method + " takes " + handler[method].length + " arguments, got " + args.length);
            return;
        }
        handler[method](...args);
    }
}
