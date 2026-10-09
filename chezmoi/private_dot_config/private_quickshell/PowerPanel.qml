pragma Singleton

// Rows for the power panel: battery readings from UPower, then the three asusd
// profiles with the active one checked. The profile is read from the state
// file power-profile.sh writes, the same one PowerProfile.qml watches, and set
// through that script, which speaks asusctl only on purpose.
//
//   bindsym $mod+Ctrl+e nop qs menu toggle power

import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

Singleton {
    id: root

    readonly property string title: "Power"
    // Set by Menu.qml while this panel is on screen; unused here.
    property bool showing: false

    readonly property string script: Quickshell.env("HOME") + "/.config/sway/power-profile.sh"
    readonly property var battery: UPower.displayDevice
    property string profile: ""

    FileView {
        path: Quickshell.env("XDG_RUNTIME_DIR") + "/power-profile"
        watchChanges: true
        preload: true
        onFileChanged: reload()
        onLoaded: root.profile = (this.text().split("\n")[0] ?? "").trim()
    }

    function duration(seconds) {
        if (!seconds)
            return "";
        const hours = Math.floor(seconds / 3600);
        const minutes = Math.round((seconds % 3600) / 60);
        return hours > 0 ? hours + "h " + minutes + "m" : minutes + "m";
    }

    function stateOf(device) {
        return device.state === UPowerDeviceState.Charging ? "charging, full in " + root.duration(device.timeToFull)
            : device.state === UPowerDeviceState.Discharging ? root.duration(device.timeToEmpty) + " left"
            : device.state === UPowerDeviceState.FullyCharged ? "full"
            : "on AC";
    }

    readonly property var batteryRows: !root.battery?.isPresent ? [] : [
        { label: "Battery " + Math.round(root.battery.percentage * 100) + "%", sub: root.stateOf(root.battery),
          glyph: Glyph.battery(root.battery.percentage * 100), info: true },
        { label: "Drawing " + Math.abs(root.battery.changeRate).toFixed(1) + " W", icon: "powerPlug", info: true },
        ...(root.battery.healthSupported
            ? [{ label: "Health " + Math.round(root.battery.healthPercentage) + "%", icon: "batteryFull", info: true }]
            : [])
    ]

    readonly property var profiles: [
        { name: "Performance", icon: "speedometer" },
        { name: "Balanced", icon: "speedometerMedium" },
        { name: "Quiet", icon: "leaf" }
    ]

    readonly property var items: [
        ...root.batteryRows,
        ...root.profiles.map(p => ({
            label: p.name,
            icon: p.icon,
            on: root.profile === p.name,
            act: () => Quickshell.execDetached([root.script, "set", p.name])
        })),
        { label: "ROG Control Center", icon: "tune", sh: "rog-control-center" }
    ]
}
