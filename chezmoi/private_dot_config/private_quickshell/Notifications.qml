pragma Singleton

// The notification daemon, in place of mako. Popups are NotificationPopups.qml;
// this holds the server, the list of popups on screen and a history.
//
// History keeps plain copies (summary, body, app, time), not the Notification
// objects. A popup that times out is expired back to the sending app as the
// protocol expects, which ends that object, and the history must outlive it.
//
// Do not disturb (ShellState.doNotDisturb) stops popups but not history.
// Critical notifications pop up anyway, as mako's config had them never time
// out.
//
// mako is still installed for machines on the waybar fallback. Its D-Bus
// activation file claims org.freedesktop.Notifications, so a notification
// sent while quickshell restarts would start mako and keep this server from
// getting the name. On endling mako.service is masked for that reason:
//   systemctl --user mask mako.service
//
// Also a panel for Menu.qml (rows = the history), so the history searches and
// navigates like every other menu.
//
//   bindsym $mod+n          nop qs notifications dismissNewest
//   bindsym $mod+Shift+n    nop qs notifications dismissAll
//   bindsym $mod+Mod1+n     nop qs menu toggle notifications

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    readonly property string title: "Notifications"
    // Set by Menu.qml while the history is on screen.
    property bool showing: false

    readonly property int historyLimit: 50
    // Used when the sender leaves the timeout to the server, the way mako's
    // default-timeout was 5000.
    readonly property int defaultTimeoutMs: 5000

    // On screen now, newest first. Each entry is the live Notification.
    property var popups: []
    // Newest first, plain objects, capped at historyLimit.
    property var history: []

    // expireTimeout is the sender's value in milliseconds, -1 for "server
    // decides", even though it is typed as a double. `notify-send -t 3000`
    // arrives as 3000, checked 2026-10-09; read as seconds that popup stayed
    // up for fifty minutes.
    function timeoutMs(notification) {
        if (notification.urgency === NotificationUrgency.Critical)
            return 0;
        return notification.expireTimeout > 0 ? notification.expireTimeout : root.defaultTimeoutMs;
    }

    function record(notification) {
        const entry = {
            id: notification.id,
            appName: notification.appName,
            summary: notification.summary,
            body: notification.body,
            time: new Date()
        };
        root.history = [entry, ...root.history].slice(0, root.historyLimit);
    }

    function show(notification) {
        const critical = notification.urgency === NotificationUrgency.Critical;
        if (ShellState.doNotDisturb && !critical)
            return;
        notification.tracked = true;
        notification.closed.connect(() => root.popups = root.popups.filter(n => n !== notification));
        root.popups = [notification, ...root.popups.filter(n => n.id !== notification.id)];
    }

    function receive(notification) {
        root.record(notification);
        root.show(notification);
    }

    function dismissNewest() {
        root.popups[0]?.dismiss();
    }

    function dismissAll() {
        root.popups.forEach(n => n.dismiss());
    }

    function invokeNewest() {
        const newest = root.popups[0];
        newest?.actions.find(a => a.identifier === "default")?.invoke();
        newest?.dismiss();
    }

    function clearHistory() {
        root.history = [];
    }

    NotificationServer {
        keepOnReload: true
        bodySupported: true
        bodyMarkupSupported: true
        actionsSupported: true
        imageSupported: true
        persistenceSupported: true
        onNotification: notification => root.receive(notification)
    }

    Ipc {
        target: "notifications"

        function dismissNewest(): void {
            root.dismissNewest();
        }

        function dismissAll(): void {
            root.dismissAll();
        }

        function invokeNewest(): void {
            root.invokeNewest();
        }

        function clearHistory(): void {
            root.clearHistory();
        }
    }

    function ago(time) {
        const minutes = Math.floor((Date.now() - time.getTime()) / 60000);
        return minutes < 1 ? "now"
            : minutes < 60 ? minutes + "m"
            : Math.floor(minutes / 60) + "h";
    }

    readonly property var items: [
        { label: "Do not disturb", icon: "bellSleep", state: "doNotDisturb",
          act: () => ShellState.toggle("doNotDisturb") },
        ...(root.history.length > 0 ? [{ label: "Clear history", icon: "bellOff", act: () => root.clearHistory() }] : []),
        ...root.history.map(entry => ({
            label: entry.summary || entry.appName,
            sub: [entry.appName, entry.body.replace(/<[^>]*>/g, ""), root.ago(entry.time)].filter(s => s).join(" · "),
            icon: "bell",
            info: true
        }))
    ]
}
