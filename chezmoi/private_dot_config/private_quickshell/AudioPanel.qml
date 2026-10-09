pragma Singleton

// Rows for the audio panel: output and input volume (Left/Right 5%, Enter
// mutes), then every sink and source, where Enter makes it the default.
// pavucontrol stays one row down for per-app streams.
//
//   bindsym $mod+Ctrl+a nop qs menu toggle audio

import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property string title: "Audio"
    // Set by Menu.qml while this panel is on screen; unused here.
    property bool showing: false
    readonly property real step: 0.05

    readonly property var devices: Pipewire.nodes.values.filter(node => node.audio && !node.isStream)
    readonly property var sinks: root.devices.filter(node => node.isSink)
    readonly property var sources: root.devices.filter(node => !node.isSink)

    // Without a tracker the nodes' volume and mute never bind; see Volume.qml.
    PwObjectTracker {
        objects: root.devices
    }

    function nameOf(node) {
        return node.description || node.nickname || node.name;
    }

    function volumeRow(node, label, icon, mutedIcon) {
        if (!node?.audio)
            return { label: label + ": none", icon: mutedIcon, info: true };
        const audio = node.audio;
        return {
            label: label + " " + (audio.muted ? "muted" : Math.round(audio.volume * 100) + "%"),
            sub: root.nameOf(node),
            icon: audio.muted ? mutedIcon : icon,
            act: () => audio.muted = !audio.muted,
            adjust: direction => audio.volume = Math.max(0, Math.min(1, audio.volume + direction * root.step))
        };
    }

    function deviceRow(node, icon, isDefault, makeDefault) {
        return { label: root.nameOf(node), icon: icon, on: isDefault, act: makeDefault };
    }

    readonly property var items: [
        root.volumeRow(Pipewire.defaultAudioSink, "Output", "volumeHigh", "volumeOff"),
        root.volumeRow(Pipewire.defaultAudioSource, "Input", "microphone", "volumeOff"),
        ...root.sinks.map(node => root.deviceRow(node, "headphones", node === Pipewire.defaultAudioSink,
            () => Pipewire.preferredDefaultAudioSink = node)),
        ...root.sources.map(node => root.deviceRow(node, "microphone", node === Pipewire.defaultAudioSource,
            () => Pipewire.preferredDefaultAudioSource = node)),
        { label: "Mixer", sub: "pavucontrol", icon: "tune", sh: "pavucontrol" }
    ]
}
