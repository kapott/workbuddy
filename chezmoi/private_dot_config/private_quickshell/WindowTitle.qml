// The focused window, as its application icon plus the title.
//
// Read from the Wayland foreign-toplevel protocol rather than from sway's IPC,
// because the toplevel carries appId, which is what turns a title into an icon.
// The lookup is heuristic: appId is whatever the toolkit felt like reporting, so
// it matches a .desktop file most of the time and nothing some of the time. No
// match just means no icon.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

Item {
    id: root

    readonly property var toplevel: ToplevelManager.activeToplevel
    readonly property string title: root.toplevel ? root.toplevel.title : ""
    readonly property string appId: root.toplevel ? root.toplevel.appId : ""
    // The .desktop scan finishes after the first bindings are evaluated, and
    // heuristicLookup is a plain function call with nothing to notify on. Reading
    // the entry count first is what makes this re-run once the scan lands;
    // without it the first window of a session never gets an icon.
    readonly property int entryCount: DesktopEntries.applications.values.length
    readonly property var entry: root.appId !== "" && root.entryCount > 0
        ? DesktopEntries.heuristicLookup(root.appId)
        : null

    implicitHeight: Theme.barHeight

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.padding
        spacing: 6

        IconImage {
            implicitSize: Theme.iconSize
            visible: source !== ""
            source: root.entry && root.entry.icon ? Quickshell.iconPath(root.entry.icon, true) : ""
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            text: root.title
            color: Theme.foreground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            elide: Text.ElideRight
        }
    }
}
