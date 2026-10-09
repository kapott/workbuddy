pragma Singleton

// Rows for the keybindings panel: every `bindsym` in the running sway config,
// with its `### Section` heading and its command, searchable like any menu.
//
// Read from `swaymsg -t get_config` each time the panel opens, so it shows
// what sway loaded rather than what is on disk, and needs no copy of the
// binding list anywhere. `set $var` lines are substituted, so `$mod+Return`
// reads `Super+Return`.
//
//   bindsym $mod+slash nop qs menu toggle keys

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string title: "Keybindings"
    // Set by Menu.qml while this panel is on screen.
    property bool showing: false

    property var bindings: []

    readonly property var modifierNames: ({ Mod4: "Super", Mod1: "Alt", Control: "Ctrl" })

    onShowingChanged: if (showing) reader.running = true

    Process {
        id: reader
        command: ["swaymsg", "-r", "-t", "get_config"]
        stdout: StdioCollector {
            onStreamFinished: root.bindings = root.parse(JSON.parse(this.text).config)
        }
    }

    // Pure. Config text in, [{ keys, section, command }] out.
    function parse(config) {
        const lines = config.split("\n").map(line => line.trim());
        const vars = root.variables(lines);
        return lines.reduce((acc, line) => {
            const heading = /^###\s+(.*)$/.exec(line);
            const mode = /^mode\s+"([^"]+)"\s*\{$/.exec(line);
            const bind = /^bindsym\s+((?:--\S+\s+)*)(\S+)\s+(.*)$/.exec(line);
            if (heading)
                return { section: heading[1], mode: "", rows: acc.rows };
            if (mode)
                return { section: acc.section, mode: mode[1], rows: acc.rows };
            if (line === "}")
                return { section: acc.section, mode: "", rows: acc.rows };
            if (!bind)
                return acc;
            const row = {
                keys: root.prettyKeys(root.substitute(bind[2], vars)),
                section: acc.mode ? acc.mode + " mode" : acc.section,
                command: root.substitute(bind[3], vars).replace(/^exec\s+/, "")
            };
            return { section: acc.section, mode: acc.mode, rows: acc.rows.concat([row]) };
        }, { section: "", mode: "", rows: [] }).rows;
    }

    function variables(lines) {
        return lines
            .map(line => /^set\s+(\$\w+)\s+(.*)$/.exec(line))
            .filter(match => match)
            .map(match => [match[1], match[2]])
            .sort((a, b) => b[0].length - a[0].length);
    }

    // Longest name first, so $ws10 is not read as $ws1 followed by a 0.
    function substitute(text, vars) {
        return vars.reduce((out, [name, value]) => out.split(name).join(value), text);
    }

    function prettyKeys(keys) {
        return keys.split("+").map(key => root.modifierNames[key] ?? key).join("+");
    }

    readonly property var items: root.bindings.map(binding => ({
        label: binding.keys,
        sub: binding.section + " · " + binding.command,
        icon: "keyboard",
        info: true
    }))
}
