pragma Singleton

// What the menu has been used for, kept for frecency (Frecency.js). One JSON
// file under quickshell's state directory for this config, so a test instance
// started from a scratch copy keeps its own and never skews the real one.
//
// Only keyed rows are recorded: apps ("app:<desktop id>") and the static menu
// items ("<menu id>/<label>"). Panel rows are not. Their order means
// something (connected first, default device first) and a frecency sort would
// fight it.

import QtQuick
import Quickshell
import Quickshell.Io
import "Frecency.js" as Frecency

Singleton {
    id: root

    property var db: ({})

    function now() {
        return Math.floor(Date.now() / 1000);
    }

    function use(key) {
        if (!key)
            return;
        root.db = Frecency.record(root.db, key, root.now());
        file.setText(JSON.stringify(root.db));
    }

    FileView {
        id: file
        path: Quickshell.statePath("usage.json")
        atomicWrites: true
        preload: true
        printErrors: false
        onLoaded: {
            try {
                root.db = JSON.parse(this.text()) ?? {};
            } catch (e) {
                root.db = {};
            }
        }
    }
}
