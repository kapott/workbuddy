// Coffee means swayidle is being held off, sleep means the normal timeout
// applies. The inhibitor object lives in Bar.qml because it has to be tied to a
// window; this is only the button.

import QtQuick

Pill {
    id: root

    required property var inhibitor

    icon: root.inhibitor.enabled ? Glyph.coffee : Glyph.sleep
    tint: root.inhibitor.enabled ? Theme.orange : Theme.dim
    tooltip: root.inhibitor.enabled ? "Idle inhibited, screen stays on" : "Normal idle timeout"

    onClicked: root.inhibitor.enabled = !root.inhibitor.enabled
}
