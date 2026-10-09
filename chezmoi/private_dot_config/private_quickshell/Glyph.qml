pragma Singleton

// Every icon in the bar, by Nerd Font codepoint.
//
// The bar used to spell its modules out as CPU, RAM, SCR, BAT, VOL, BT and PRF
// because waybar's default format strings are text. These are the same readings
// as glyphs, which is the whole reason ttf-hack-nerd is in packages.toml.
//
// Written as String.fromCodePoint rather than as literal glyphs for two reasons:
// the Material Design range sits above U+FFFF, where a pasted glyph is a
// surrogate pair that no editor shows you the value of, and a codepoint here can
// be checked against the font without rendering anything.
//
// Check the name, not just that the codepoint exists. Every value below was
// present in the font on the first try and two of them were the wrong icon:
// 0xf13c6 is md-table_lock, not md-speedometer_medium, and 0xf092b is
// md-wifi_strength_alert_outline, not md-wifi_strength_outline. Both would have
// rendered something plausible-looking at 16px.
//
//   python -c "from fontTools.ttLib import TTFont; \
//     f = TTFont('/usr/share/fonts/TTF/HackNerdFontMono-Regular.ttf'); \
//     print([t.cmap.get(0xefc5) for t in f['cmap'].tables])"
//
// nf-md-* names are Material Design Icons, nf-fa-* Font Awesome, nf-oct-*
// Octicons.

import Quickshell

Singleton {
    // nf-oct-cpu is a chip, nf-fa-memory a DIMM. nf-md-memory is also a chip and
    // sits next to the CPU in the bar, where the two are indistinguishable.
    readonly property string cpu: String.fromCodePoint(0xf4bc)
    readonly property string memory: String.fromCodePoint(0xefc5)

    // nf-md-thermometer, nf-md-thermometer_alert
    readonly property string thermometer: String.fromCodePoint(0xf050f)
    readonly property string thermometerAlert: String.fromCodePoint(0xf0e01)

    // nf-md-brightness_7
    readonly property string brightness: String.fromCodePoint(0xf00e0)

    // nf-md-volume_high / _low / _medium / _off
    readonly property string volumeHigh: String.fromCodePoint(0xf057e)
    readonly property string volumeLow: String.fromCodePoint(0xf057f)
    readonly property string volumeMedium: String.fromCodePoint(0xf0580)
    readonly property string volumeOff: String.fromCodePoint(0xf0581)

    // nf-md-bluetooth, _connect, _off
    readonly property string bluetooth: String.fromCodePoint(0xf00af)
    readonly property string bluetoothConnect: String.fromCodePoint(0xf00b1)
    readonly property string bluetoothOff: String.fromCodePoint(0xf00b2)

    // nf-md-wifi_off, nf-md-ethernet, nf-md-lan_disconnect
    readonly property string wifiOff: String.fromCodePoint(0xf05aa)
    readonly property string ethernet: String.fromCodePoint(0xf0200)
    readonly property string lanDisconnect: String.fromCodePoint(0xf0319)

    // nf-md-coffee keeps the screen awake, nf-md-sleep lets it idle out.
    readonly property string coffee: String.fromCodePoint(0xf0176)
    readonly property string sleep: String.fromCodePoint(0xf04b2)

    // nf-md-clock
    readonly property string clock: String.fromCodePoint(0xf0954)

    // asusd profiles: nf-md-speedometer, _medium, nf-md-leaf
    readonly property string speedometer: String.fromCodePoint(0xf04c5)
    readonly property string speedometerMedium: String.fromCodePoint(0xf0f85)
    readonly property string leaf: String.fromCodePoint(0xf032a)

    // nf-md-help_circle_outline, for a reading we could not make sense of
    readonly property string unknown: String.fromCodePoint(0xf0625)

    // nf-md-wifi_strength_outline, then _1 through _4. The four steps are three
    // apart because each is followed by its _alert and _lock variants, which is
    // why this is a table and not an addition.
    readonly property var wifiBars: [
        String.fromCodePoint(0xf092f),  // no signal
        String.fromCodePoint(0xf091f),
        String.fromCodePoint(0xf0922),
        String.fromCodePoint(0xf0925),
        String.fromCodePoint(0xf0928)
    ]

    /// Wi-Fi glyph for a 0-100 signal strength.
    function wifi(strength: real): string {
        return wifiBars[Math.min(4, Math.max(0, Math.ceil(strength / 25)))];
    }

    // nf-md-battery is full and nf-md-battery_10 .. _90 follow it in order, so
    // the deciles are contiguous from 0xf007a. nf-md-battery_outline is empty,
    // nf-md-battery_alert and nf-md-battery_charging are elsewhere in the range.
    readonly property string batteryFull: String.fromCodePoint(0xf0079)
    readonly property string batteryEmpty: String.fromCodePoint(0xf008e)
    readonly property string batteryAlert: String.fromCodePoint(0xf0083)
    readonly property string batteryCharging: String.fromCodePoint(0xf0084)
    readonly property string powerPlug: String.fromCodePoint(0xf06a5)

    /// Battery glyph for a 0-100 charge.
    function battery(percent: real): string {
        const decile = Math.round(percent / 10);
        if (decile <= 0) return batteryEmpty;
        if (decile >= 10) return batteryFull;
        return String.fromCodePoint(0xf007a + decile - 1);
    }

    // The menu. All nf-md-*, looked up by glyph name in the font on 2026-10-09
    // rather than by codepoint, so the name in each comment is the font's own.
    readonly property string apps: String.fromCodePoint(0xf003b)             // md-apps
    readonly property string camera: String.fromCodePoint(0xf0100)           // md-camera
    readonly property string toggle: String.fromCodePoint(0xf0521)           // md-toggle_switch
    readonly property string chip: String.fromCodePoint(0xf061a)             // md-chip
    readonly property string power: String.fromCodePoint(0xf0425)            // md-power
    readonly property string update: String.fromCodePoint(0xf06b0)           // md-update
    readonly property string keyboard: String.fromCodePoint(0xf030c)         // md-keyboard
    readonly property string keyboardLight: String.fromCodePoint(0xf0313)    // md-keyboard_variant
    readonly property string lock: String.fromCodePoint(0xf033e)             // md-lock
    readonly property string logout: String.fromCodePoint(0xf0343)           // md-logout
    readonly property string restart: String.fromCodePoint(0xf0709)          // md-restart
    readonly property string powerSleep: String.fromCodePoint(0xf0904)       // md-power_sleep
    readonly property string monitor: String.fromCodePoint(0xf0379)          // md-monitor
    readonly property string screenshot: String.fromCodePoint(0xf0e51)       // md-monitor_screenshot
    readonly property string selection: String.fromCodePoint(0xf0489)        // md-selection
    readonly property string draw: String.fromCodePoint(0xf0f49)             // md-draw
    readonly property string textRecognition: String.fromCodePoint(0xf113d)  // md-text_recognition
    readonly property string qrcode: String.fromCodePoint(0xf0432)           // md-qrcode
    readonly property string gpu: String.fromCodePoint(0xf08ae)              // md-expansion_card
    readonly property string touchpad: String.fromCodePoint(0xf0741)         // md-gesture_tap
    readonly property string bar: String.fromCodePoint(0xf0293)              // md-fullscreen
    readonly property string bell: String.fromCodePoint(0xf009a)             // md-bell
    readonly property string bellOff: String.fromCodePoint(0xf009b)          // md-bell_off
    readonly property string bellSleep: String.fromCodePoint(0xf00a0)        // md-bell_sleep
    readonly property string packageUpdate: String.fromCodePoint(0xf03d6)    // md-package_variant
    readonly property string download: String.fromCodePoint(0xf01da)         // md-download
    readonly property string refresh: String.fromCodePoint(0xf0450)          // md-refresh
    readonly property string cog: String.fromCodePoint(0xf0493)              // md-cog
    readonly property string tune: String.fromCodePoint(0xf062e)             // md-tune
    readonly property string laptop: String.fromCodePoint(0xf0322)           // md-laptop
    readonly property string headphones: String.fromCodePoint(0xf02cb)       // md-headphones
    readonly property string microphone: String.fromCodePoint(0xf036c)       // md-microphone
    readonly property string wifiOn: String.fromCodePoint(0xf05a9)           // md-wifi
    readonly property string vpn: String.fromCodePoint(0xf0582)              // md-vpn
    readonly property string check: String.fromCodePoint(0xf012c)            // md-check
    readonly property string chevronRight: String.fromCodePoint(0xf0142)     // md-chevron_right
    readonly property string magnify: String.fromCodePoint(0xf0349)          // md-magnify
}
