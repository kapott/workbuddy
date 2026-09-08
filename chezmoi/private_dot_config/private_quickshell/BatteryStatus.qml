// Charge of whatever UPower calls the display device, which on a laptop is the
// internal battery and on a desktop is nothing at all.

import QtQuick
import Quickshell.Services.UPower

Pill {
    id: root

    readonly property var battery: UPower.displayDevice
    readonly property bool present: root.battery && root.battery.isLaptopBattery && root.battery.isPresent
    readonly property int percent: root.present ? Math.round(root.battery.percentage * 100) : 0
    readonly property bool charging: root.present && root.battery.state === UPowerDeviceState.Charging
    readonly property bool full: root.present && root.battery.state === UPowerDeviceState.FullyCharged

    visible: root.present
    icon: root.full ? Glyph.powerPlug
        : root.charging ? Glyph.batteryCharging
        : root.percent <= 15 ? Glyph.batteryAlert
        : Glyph.battery(root.percent)
    label: root.percent + "%"
    tint: root.charging || root.full ? Theme.green
        : root.percent <= 15 ? Theme.red
        : root.percent <= 30 ? Theme.amber
        : Theme.cyan
    tooltip: {
        if (!root.present)
            return "";
        const watts = Math.abs(root.battery.changeRate).toFixed(1) + "W";
        const seconds = root.charging ? root.battery.timeToFull : root.battery.timeToEmpty;
        if (seconds <= 0)
            return root.percent + "%, " + watts;
        const hours = Math.floor(seconds / 3600);
        const minutes = Math.round((seconds % 3600) / 60);
        return root.percent + "%, " + watts + ", " + hours + "h " + minutes + "m "
            + (root.charging ? "to full" : "left");
    }
}
