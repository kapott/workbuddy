pragma Singleton

// The menu on $mod+space: a search field over a list, Omarchy's walker menu
// redrawn in this palette. What it lists is data in MenuTree.js; this file is
// the state and the window.
//
//   bindsym $mod+space nop qs menu toggle root
//   qs ipc call menu toggle system
//
// Typing at the top level searches every leaf of the tree and every installed
// app at once. Keys: Up/Down or Ctrl+j/k move, Enter runs, Right opens a
// submenu, Left/Right change a value such as volume, Escape clears the search,
// then goes back, then closes. Backspace in an empty field goes back.
//
// The panels are menus too, with rows from AudioPanel.qml and its siblings,
// so they search and navigate the same way.

import QtQuick
import Quickshell
import Quickshell.I3
import Quickshell.Wayland
import Quickshell.Widgets
import "MenuTree.js" as MenuTree
import "Frecency.js" as Frecency

Singleton {
    id: root

    // All of the menu's state, replaced whole by update() so every binding that
    // reads it sees one consistent change.
    // prompt is set while the field asks for a secret instead of a search:
    // { label, submit(text) }. The typed secret lives in query until the
    // prompt is submitted or left, and every way out clears it.
    property var view: ({ open: false, screen: null, stack: [], query: "", selected: 0, armed: -1, pointerLive: false, prompt: null })

    readonly property string current: root.topOf(root.view)
    readonly property var items: root.view.prompt
        ? [{ label: root.view.prompt.label, sub: "Enter to connect, Escape to go back", icon: "lock", info: true }]
        : root.itemsFor(root.current, root.view.query, root.apps, root.panels, Usage.db)

    // Menus whose rows are live data rather than MenuTree entries.
    readonly property var panels: ({
        audio: AudioPanel,
        bluetooth: BluetoothPanel,
        network: NetworkPanel,
        tailscale: TailscalePanel,
        power: PowerPanel,
        keys: KeysPanel,
        notifications: Notifications
    })

    // Reading .values in a binding is what makes it re-run once the .desktop
    // scan lands; see "Things that bit" in the README.
    readonly property var apps: DesktopEntries.applications.values
        .filter(entry => !entry.noDisplay)
        .map(entry => ({ label: entry.name, sub: entry.genericName || entry.comment || "", entry: entry, key: "app:" + entry.id }))
        .sort((a, b) => a.label.localeCompare(b.label))

    function update(change) {
        root.view = Object.assign({}, root.view, change);
    }

    // Tells each panel whether it is on screen, so the network panel scans and
    // the tailscale panel polls only while someone is looking. Pushed from here
    // rather than read by the panels, which would make the singletons depend on
    // each other in a circle.
    //
    // topOf(view), not root.current. current is a binding on view too, and
    // QML does not promise it has been re-evaluated by the time this handler
    // runs. Reading it here saw the previous menu, so a panel learned it was
    // showing only on the next change, and opened empty.
    onViewChanged: {
        const top = root.topOf(root.view);
        Object.entries(root.panels).forEach(([id, panel]) => panel.showing = root.view.open && top === id);
    }

    function topOf(view) {
        return view.stack.length ? view.stack[view.stack.length - 1] : "";
    }

    // Search ranks by match plus frecency (MenuTree.search, Frecency.js). With
    // no query the static menus keep their order, and Apps lists the most
    // frecent first, then the rest by name, the way z ranks a bare `z`.
    function itemsFor(id, query, apps, panels, usage) {
        if (id === "")
            return [];
        const now = Usage.now();
        const pool = id === "apps" ? apps
            : panels[id] ? panels[id].items
            : id === "root" && query !== "" ? MenuTree.leaves("root", "").concat(apps)
            : MenuTree.itemsOf(id);
        if (query !== "")
            return MenuTree.search(pool, query, key => Frecency.bonus(usage, key, now));
        if (id === "apps")
            return root.byFrecency(pool, usage, now);
        return pool;
    }

    function byFrecency(items, usage, now) {
        return items
            .map((item, index) => ({ item, index, score: Frecency.score(usage, item.key, now) }))
            .sort((a, b) => (b.score - a.score) || (a.index - b.index))
            .map(hit => hit.item);
    }

    function focusedScreen() {
        const name = I3.focusedMonitor?.name;
        return Quickshell.screens.find(s => s.name === name) ?? Quickshell.screens[0];
    }

    function open(id) {
        root.update({ open: true, screen: root.focusedScreen(), stack: [id], query: "", selected: 0, armed: -1, pointerLive: false, prompt: null });
    }

    function close() {
        root.update({ open: false, stack: [], query: "", selected: 0, armed: -1, pointerLive: false, prompt: null });
    }

    function toggle(id) {
        if (root.view.open && root.view.stack[0] === id)
            root.close();
        else
            root.open(id);
    }

    function enter(id) {
        root.update({ stack: root.view.stack.concat([id]), query: "", selected: 0, armed: -1, pointerLive: false, prompt: null });
    }

    function back() {
        if (root.view.stack.length > 1)
            root.update({ stack: root.view.stack.slice(0, -1), query: "", selected: 0, armed: -1, pointerLive: false, prompt: null });
        else
            root.close();
    }

    function move(delta) {
        const count = root.items.length;
        if (count > 0)
            root.update({ selected: (root.view.selected + delta + count) % count, armed: -1 });
    }

    function search(query) {
        root.update({ query: query, selected: 0, armed: -1, pointerLive: false });
    }

    // A surface that maps under a resting pointer gets a position event without
    // the pointer moving, and so does a list redrawn under it. The first one
    // after any reset only marks the pointer live; selection follows from the
    // next. Omarchy solves the same thing in Ui/PointerMoveGate.qml.
    function hover(index) {
        if (root.view.pointerLive)
            root.update({ selected: index, armed: -1 });
        else
            root.update({ pointerLive: true });
    }

    function activate(index) {
        const item = root.items[index];
        if (!item)
            return;
        if (item.info)
            return;
        if (item.menu)
            return root.enter(item.menu);
        if (item.confirm && root.view.armed !== index)
            return root.update({ selected: index, armed: index });
        if (item.prompt)
            return root.update({ prompt: Object.assign({ back: { query: root.view.query, selected: index } }, item.prompt), query: "", armed: -1 });
        if (item.act && !item.close)
            return item.act();
        root.close();
        root.run(item);
    }

    // DesktopEntry.execute() does not open a terminal for Terminal=true
    // entries, so those go through kitty by hand.
    function run(item) {
        Usage.use(item.key);
        if (item.act)
            item.act();
        else if (item.entry && item.entry.runInTerminal)
            Quickshell.execDetached(["kitty", "-e", ...item.entry.command]);
        else if (item.entry)
            item.entry.execute();
        else if (item.sh)
            Quickshell.execDetached(["sh", "-c", item.sh]);
        else if (item.call) {
            const [target, method, ...args] = item.call.split(" ");
            IpcRegistry.call(target, method, args);
        }
    }

    // While a prompt is up only Enter and Escape mean anything; every other
    // key, arrows included, belongs to the text field.
    function handlePromptKey(event) {
        const prompt = root.view.prompt;
        if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && root.view.query !== "") {
            const secret = root.view.query;
            root.close();
            prompt.submit(secret);
        } else if (event.key === Qt.Key_Escape || (event.key === Qt.Key_Backspace && root.view.query === "")) {
            // Back to the search and the row the prompt came from. Dropping
            // to an empty search left the selection on row 0, the Wi-Fi
            // switch, and the next Enter turned Wi-Fi off (2026-10-09).
            root.update({ prompt: null, query: prompt.back.query, selected: prompt.back.selected, pointerLive: false });
        } else {
            return;
        }
        event.accepted = true;
    }

    function handleKey(event) {
        if (root.view.prompt)
            return root.handlePromptKey(event);
        const ctrl = event.modifiers & Qt.ControlModifier;
        const empty = root.view.query === "";
        const selectedItem = root.items[root.view.selected];
        if (event.key === Qt.Key_Down || (ctrl && (event.key === Qt.Key_J || event.key === Qt.Key_N)) || event.key === Qt.Key_Tab)
            root.move(1);
        else if (event.key === Qt.Key_Up || (ctrl && (event.key === Qt.Key_K || event.key === Qt.Key_P)) || event.key === Qt.Key_Backtab)
            root.move(-1);
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
            root.activate(root.view.selected);
        else if ((event.key === Qt.Key_Left || event.key === Qt.Key_Right) && selectedItem?.adjust)
            selectedItem.adjust(event.key === Qt.Key_Right ? 1 : -1);
        else if (event.key === Qt.Key_Right && selectedItem?.menu)
            root.activate(root.view.selected);
        else if (event.key === Qt.Key_Escape)
            empty ? root.back() : root.search("");
        else if ((event.key === Qt.Key_Backspace || event.key === Qt.Key_Left) && empty)
            root.back();
        else
            return;
        event.accepted = true;
    }

    Ipc {
        target: "menu"

        function toggle(id: string): void {
            root.toggle(id);
        }

        function open(id: string): void {
            root.open(id);
        }

        function close(): void {
            root.close();
        }
    }

    PanelWindow {
        id: window

        visible: root.view.open
        screen: root.view.screen
        color: Theme.scrim
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-menu"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        onVisibleChanged: if (visible) input.forceActiveFocus()

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: Math.round(parent.height * 0.2)
            width: Theme.menuWidth
            height: content.implicitHeight + Theme.padding * 2
            color: Theme.background
            border.color: Theme.raised
            border.width: 1
            radius: Theme.menuRadius

            // Clicks inside the frame must not reach the scrim, which closes.
            MouseArea {
                anchors.fill: parent
            }

            Column {
                id: content
                x: Theme.padding
                y: Theme.padding
                width: parent.width - Theme.padding * 2
                spacing: Theme.gap * 2

                Row {
                    width: parent.width
                    height: Theme.menuRowHeight
                    spacing: Theme.padding

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Glyph.magnify
                        color: Theme.dim
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.iconSize
                    }

                    TextInput {
                        id: input
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - title.implicitWidth - Theme.iconSize - Theme.padding * 2
                        text: root.view.query
                        echoMode: root.view.prompt ? TextInput.Password : TextInput.Normal
                        color: Theme.foreground
                        selectionColor: Theme.raised
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize + 2
                        clip: true
                        onTextEdited: root.search(text)
                        Keys.onPressed: event => root.handleKey(event)

                        Text {
                            visible: input.text === ""
                            text: root.view.prompt ? "Password" : "Search"
                            color: Theme.dim
                            font: input.font
                        }
                    }

                    Text {
                        id: title
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.view.stack.map(id => id === "apps" ? "Apps" : root.panels[id]?.title ?? MenuTree.menus[id]?.title ?? id).join(" › ")
                        color: Theme.dim
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                    }
                }

                ListView {
                    id: list
                    width: parent.width
                    height: Math.max(1, Math.min(count, Theme.menuMaxRows)) * Theme.menuRowHeight
                    clip: true
                    model: root.items
                    currentIndex: root.view.selected
                    highlightMoveDuration: 0
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: MenuRow {
                        width: list.width
                        selected: index === root.view.selected
                        armed: index === root.view.armed
                        onHovered: root.hover(index)
                        onChosen: root.activate(index)
                    }

                    Text {
                        visible: list.count === 0
                        anchors.centerIn: parent
                        text: "No match"
                        color: Theme.dim
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                    }
                }
            }
        }
    }
}
