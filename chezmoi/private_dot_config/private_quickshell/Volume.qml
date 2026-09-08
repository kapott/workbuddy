// Output volume, straight off the pipewire default sink.
//
// PwObjectTracker is not optional: quickshell only binds a node's audio data
// while something is tracking it, so without it volume and muted stay at their
// defaults and the indicator reads 0% forever.

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Pill {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var audio: root.sink ? root.sink.audio : null
    readonly property bool muted: root.audio ? root.audio.muted : true
    readonly property int percent: root.audio ? Math.round(root.audio.volume * 100) : 0

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    icon: root.muted ? Glyph.volumeOff
        : root.percent > 66 ? Glyph.volumeHigh
        : root.percent > 33 ? Glyph.volumeMedium
        : Glyph.volumeLow
    label: root.muted ? "" : root.percent + "%"
    tint: root.muted ? Theme.dim : Theme.yellow
    tooltip: root.sink ? (root.sink.description || root.sink.name) : "No audio sink"

    onClicked: mouse => {
        if (mouse.button === Qt.RightButton) {
            if (root.audio)
                root.audio.muted = !root.muted;
        } else {
            Quickshell.execDetached(["pavucontrol"]);
        }
    }

    // 5% a notch, the same step the volume keys use.
    onWheel: wheel => {
        if (!root.audio)
            return;
        const step = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
        root.audio.volume = Math.max(0, Math.min(1, root.audio.volume + step));
    }
}
