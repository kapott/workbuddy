pragma Singleton

// The one entry point for on-screen displays driven from a key binding.
// sway binds keys to `nop qs osd <method> [arg]` and Bindings.qml routes them
// here, as does `qs ipc call osd ...` from a script.
//
// The clock is held open while $mod+t is down, so sway fires twice: `clock` on
// the press and `clockRelease` on the release.
//
// The level keys change the value themselves and then show it, so the number
// on screen is the one that was set rather than a second reading:
//   volume +5 / -5      default sink through pipewire, capped at 150% like the
//                       old `wpctl set-volume -l 1.5`
//   mute, micMute       default sink / source
//   brightness +5 / -5  percent, through brightnessctl, which owns the udev
//                       rule that makes the sysfs file writable
//   kbdLight +1 / -1    asus::kbd_backlight steps, 0 to 3
//
// A singleton because there must be exactly one handler per target. Variants
// gives each screen its own overlay, and registering the same target once per
// screen makes quickshell refuse the duplicates.

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property real volumeCap: 1.5

    signal clockRequested()
    signal clockReleased()
    /// fraction is 0 to 1 of the bar's length; label is what to print beside it.
    signal levelShown(string icon, real fraction, string label)

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    PwObjectTracker {
        objects: [root.sink, root.source].filter(node => node)
    }

    function showVolume() {
        const audio = root.sink?.audio;
        if (!audio)
            return;
        const percent = Math.round(audio.volume * 100);
        const icon = audio.muted ? Glyph.volumeOff
            : percent > 66 ? Glyph.volumeHigh
            : percent > 33 ? Glyph.volumeMedium
            : Glyph.volumeLow;
        root.levelShown(icon, audio.muted ? 0 : Math.min(1, audio.volume), audio.muted ? "muted" : percent + "%");
    }

    // A node pipewire has not finished describing reports default values, and
    // writing to it writes those too. On 2026-10-09 the first mic mute after a
    // bluetooth headset became the default source came back at volume 1.00
    // instead of 0.62; not reproduced since, so this guard is cheap insurance.
    function writable(node) {
        return node?.ready && node.audio ? node.audio : null;
    }

    function changeVolume(step) {
        const audio = root.writable(root.sink);
        if (!audio)
            return;
        audio.volume = Math.max(0, Math.min(root.volumeCap, audio.volume + step / 100));
        root.showVolume();
    }

    function toggleMute(node, icon) {
        const audio = root.writable(node);
        if (!audio)
            return;
        audio.muted = !audio.muted;
        if (node === root.sink)
            root.showVolume();
        else
            root.levelShown(audio.muted ? Glyph.volumeOff : icon, audio.muted ? 0 : audio.volume, audio.muted ? "mic muted" : "mic on");
    }

    // brightnessctl -m prints "device,class,current,percent,max", e.g.
    // "amdgpu_bl1,backlight,120,47%,255".
    function brightnessctl(args, icon) {
        light.icon = icon;
        light.command = ["brightnessctl", "-m", ...args];
        light.running = true;
    }

    Process {
        id: light
        property string icon
        stdout: StdioCollector {
            onStreamFinished: {
                const [, , current, percent, max] = this.text.trim().split(",");
                root.levelShown(light.icon, Number(current) / Number(max), percent);
            }
        }
    }

    Ipc {
        target: "osd"

        function clock(): void {
            root.clockRequested();
        }

        function clockRelease(): void {
            root.clockReleased();
        }

        function volume(step: string): void {
            root.changeVolume(Number(step));
        }

        function mute(): void {
            root.toggleMute(root.sink, Glyph.volumeHigh);
        }

        function micMute(): void {
            root.toggleMute(root.source, Glyph.microphone);
        }

        function brightness(step: string): void {
            root.brightnessctl(["set", Math.abs(Number(step)) + "%" + (Number(step) < 0 ? "-" : "+")], Glyph.brightness);
        }

        function kbdLight(step: string): void {
            root.brightnessctl(["-d", "asus::kbd_backlight", "set", Math.abs(Number(step)) + (Number(step) < 0 ? "-" : "+")], Glyph.keyboardLight);
        }
    }
}
