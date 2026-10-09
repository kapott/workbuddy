// Coffee means swayidle is being held off, sleep means the normal timeout
// applies. The inhibitor object lives in Bar.qml because it has to be tied to a
// window, and its switch in ShellState; this is only the button.

import QtQuick

Pill {
    id: root


    icon: ShellState.idleInhibited ? Glyph.coffee : Glyph.sleep
    tint: ShellState.idleInhibited ? Theme.orange : Theme.dim
    tooltip: ShellState.idleInhibited ? "Idle inhibited, screen stays on" : "Normal idle timeout"

    onClicked: ShellState.toggle("idleInhibited")
}
