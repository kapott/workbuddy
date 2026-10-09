.pragma library

// Every menu Menu.qml can show, as data. Omarchy's tree
// (default/omarchy/omarchy-menu.jsonc) cut down to what endling has. There
// are no install/remove/style branches, because chezmoi manages packages and
// themes here rather than a menu.
//
// An item does one of:
//   menu: "<id>"            open that submenu
//   sh: "<command>"         run with sh -c, detached; ~ and pipes work
//   call: "<target> <method> [arg]"   an Ipc call, the same as a `nop qs` binding
// and may carry:
//   icon: "<Glyph property>"
//   state: "<ShellState switch>"   draws a check while the switch is on
//   confirm: true                  first Enter arms, second runs
//
// "apps" and the panels (audio, bluetooth, network, tailscale, power, keys,
// notifications) are not
// listed here. Menu.qml fills them live: apps from the .desktop entries, panels
// from the *Panel.qml providers, whose rows may also carry
//   act: function           run in place, the panel stays open
//   close: true             close the menu after act
//   adjust: function(step)  Left/Right change a value, step is -1 or +1
//   info: true              a reading, Enter does nothing
//   glyph: "<text>"         an icon computed from live data, instead of icon
//   on: bool                draws a check, like state does for a switch
//   sub: "<text>"           a dim second column
//
// Capture commands sleep first so the menu surface is gone before grim runs.
// tesseract has only the Dutch model installed (`tesseract --list-langs`), which
// reads English text well enough; add tesseract-data-eng for better results.

var shots = "~/Pictures/Screenshots";
var stamp = "$(date +%Y%m%d-%H%M%S)";
var region = 'sleep 0.2; grim -g "$(slurp)" -';

var menus = {
    root: {
        title: "Menu",
        items: [
            { label: "Apps", icon: "apps", menu: "apps" },
            { label: "Audio", icon: "volumeHigh", menu: "audio" },
            { label: "Bluetooth", icon: "bluetooth", menu: "bluetooth" },
            { label: "Network", icon: "wifiOn", menu: "network" },
            { label: "Tailscale", icon: "vpn", menu: "tailscale" },
            { label: "Power", icon: "batteryFull", menu: "power" },
            { label: "Capture", icon: "camera", menu: "capture" },
            { label: "Toggle", icon: "toggle", menu: "toggle" },
            { label: "Hardware", icon: "chip", menu: "hardware" },
            { label: "Update", icon: "update", menu: "update" },
            { label: "Notifications", icon: "bell", menu: "notifications" },
            { label: "Keybindings", icon: "keyboard", menu: "keys" },
            { label: "System", icon: "power", menu: "system" }
        ]
    },
    capture: {
        title: "Capture",
        items: [
            { label: "Screen to clipboard", icon: "screenshot", sh: "sleep 0.2; grim - | wl-copy" },
            { label: "Region to clipboard", icon: "selection", sh: region + " | wl-copy" },
            { label: "Region to file", icon: "download",
              sh: "mkdir -p " + shots + " && " + region.replace(/ -$/, "") + " " + shots + "/" + stamp + ".png" },
            { label: "Annotate region", icon: "draw", sh: "flameshot gui" },
            { label: "Text from region", icon: "textRecognition",
              sh: region + " | tesseract - - -l nld 2>/dev/null | wl-copy && notify-send 'Text copied'" },
            { label: "QR code from region", icon: "qrcode",
              sh: region + " | zbarimg -q --raw - | wl-copy && notify-send 'QR code copied'" }
        ]
    },
    toggle: {
        title: "Toggle",
        items: [
            { label: "Keep screen awake", icon: "coffee", call: "state toggle idleInhibited", state: "idleInhibited" },
            { label: "Do not disturb", icon: "bellSleep", call: "state toggle doNotDisturb", state: "doNotDisturb" },
            { label: "Bar", icon: "bar", call: "state toggle barVisible", state: "barVisible" },
            { label: "On-screen keyboard", icon: "keyboard", sh: "~/.config/sway/toggle-osk.sh" },
            { label: "Touchpad", icon: "touchpad", sh: "swaymsg input type:touchpad events toggle enabled disabled" }
        ]
    },
    hardware: {
        title: "Hardware",
        items: [
            { label: "Displays", icon: "monitor", menu: "displays" },
            { label: "Power profile", icon: "speedometer", menu: "profile" },
            { label: "GPU mode", icon: "gpu", menu: "gpu" },
            { label: "Keyboard light", icon: "keyboardLight", menu: "kbdlight" },
            { label: "ROG Control Center", icon: "tune", sh: "rog-control-center" }
        ]
    },
    displays: {
        title: "Displays",
        items: [
            { label: "Laptop panel only", icon: "laptop", sh: "~/.config/sway/display.sh internal-only" },
            { label: "External only", icon: "monitor", sh: "~/.config/sway/display.sh external-only" },
            { label: "Extend right", icon: "monitor", sh: "~/.config/sway/display.sh extend right" },
            { label: "Extend left", icon: "monitor", sh: "~/.config/sway/display.sh extend left" },
            { label: "Extend up", icon: "monitor", sh: "~/.config/sway/display.sh extend up" },
            { label: "Kick external", icon: "refresh", sh: "~/.config/sway/display.sh kick" }
        ]
    },
    // power-profile.sh speaks asusctl only, on purpose; see that script.
    profile: {
        title: "Power profile",
        items: [
            { label: "Performance", icon: "speedometer", sh: "~/.config/sway/power-profile.sh set Performance" },
            { label: "Balanced", icon: "speedometerMedium", sh: "~/.config/sway/power-profile.sh set Balanced" },
            { label: "Quiet", icon: "leaf", sh: "~/.config/sway/power-profile.sh set Quiet" }
        ]
    },
    gpu: {
        title: "GPU mode, applies at next login",
        items: [
            { label: "Integrated", icon: "gpu", sh: "supergfxctl -m Integrated && notify-send 'GPU: Integrated' 'Log out to apply'" },
            { label: "Hybrid", icon: "gpu", sh: "supergfxctl -m Hybrid && notify-send 'GPU: Hybrid' 'Log out to apply'" }
        ]
    },
    kbdlight: {
        title: "Keyboard light",
        items: [0, 1, 2, 3].map(function (level) {
            return { label: ["Off", "Low", "Medium", "High"][level], icon: "keyboardLight",
                     sh: "brightnessctl -d asus::kbd_backlight set " + level };
        })
    },
    update: {
        title: "Update",
        items: [
            { label: "System packages", icon: "packageUpdate", sh: "kitty --hold -e paru -Syu" },
            { label: "Firmware", icon: "chip", sh: "kitty --hold -e fwupdmgr update" },
            { label: "Dotfiles", icon: "refresh", sh: "kitty --hold -e chezmoi update -v" }
        ]
    },
    system: {
        title: "System",
        items: [
            { label: "Lock", icon: "lock", sh: "swaylock -f" },
            { label: "Suspend", icon: "powerSleep", sh: "systemctl suspend" },
            { label: "Log out", icon: "logout", sh: "swaymsg exit", confirm: true },
            { label: "Reboot", icon: "restart", sh: "systemctl reboot", confirm: true },
            { label: "Shut down", icon: "power", sh: "systemctl poweroff", confirm: true }
        ]
    }
};

// A menu's items, each with the key Usage.qml records it under.
function itemsOf(id) {
    return menus[id].items.map(function (item) {
        return item.menu ? item : Object.assign({ key: id + "/" + item.label }, item);
    });
}

// Every runnable item under a menu, labelled with its path, so typing at the
// top level finds "Capture › Text from region" without opening Capture first.
// The key stays the one itemsOf gives, so a use counts from either place.
function leaves(id, path) {
    return itemsOf(id).reduce(function (found, item) {
        var label = path ? path + " › " + item.label : item.label;
        if (item.menu && menus[item.menu])
            return found.concat(leaves(item.menu, label));
        if (item.menu)
            return found;
        return found.concat([Object.assign({}, item, { label: label })]);
    }, []);
}

function subsequence(text, query) {
    return Array.from(text).reduce(function (i, ch) {
        return i < query.length && ch === query[i] ? i + 1 : i;
    }, 0) === query.length;
}

// How well an item matches, in tiers 100 apart, best first:
//   500  the name starts with the query        "fire" -> Firefox
//   400  a word starts with it, or the initials do   "rcc" -> ROG Control Center
//   300  the label contains it
//   200  the second column contains it          "terminal" -> Alacritty
//   100  the label's letters in order with gaps  "frfx" -> Firefox
// The name is the last part of a path label, so "Capture › Text from region"
// starts with "text". The path separator counts as a space, so "toggle bar"
// finds "Toggle › Bar". Within a tier an earlier position wins by a few points.
// The loose last tier looks at the label only: over a long second column
// almost any five letters occur in order somewhere. -1 is no match.
function score(item, query) {
    var q = query.toLowerCase();
    var name = item.label.toLowerCase().split(" › ").pop();
    var label = item.label.toLowerCase().split(" › ").join(" ");
    var words = name.split(/[\s\-_.]+/).filter(function (w) { return w; });
    var initials = words.map(function (w) { return w[0]; }).join("");
    var sub = (item.sub || "").toLowerCase();
    if (name.indexOf(q) === 0)
        return 500;
    if (words.some(function (w) { return w.indexOf(q) === 0; }) || initials.indexOf(q) === 0)
        return 400;
    if (label.indexOf(q) >= 0)
        return 300 - Math.min(9, label.indexOf(q));
    if (sub.indexOf(q) >= 0)
        return 200 - Math.min(9, sub.indexOf(q));
    return subsequence(name, q) ? 100 : -1;
}

// Hits ordered by match plus frecency; bonus(key) is Frecency.bonus with the
// db and the time already bound, so this file stays free of state.
function search(items, query, bonus) {
    return items
        .map(function (item, index) { return { item: item, index: index, match: score(item, query) }; })
        .filter(function (hit) { return hit.match >= 0; })
        .map(function (hit) { return Object.assign(hit, { total: hit.match + bonus(hit.item.key) }); })
        .sort(function (a, b) { return (b.total - a.total) || (a.index - b.index); })
        .map(function (hit) { return hit.item; });
}
