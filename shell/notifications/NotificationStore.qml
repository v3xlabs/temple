pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

// Owns the notification server and the history the bell lists. History entries
// are plain data so they survive restarts; `id` links an entry to its live
// notification while the sender keeps it open.
Singleton {
    id: root

    readonly property int limit: 50
    property var history: []
    property int unread: 0
    property bool doNotDisturb: false

    signal popupRequested(Notification notification)

    function live(id: int): var {
        return id > 0 ? server.trackedNotifications.values.find(notification => notification.id === id) ?? null : null;
    }

    function defaultAction(notification: var): var {
        return notification?.actions.find(action => action.identifier === "default") ?? null;
    }

    function remove(item: var) {
        root.live(item.id)?.dismiss();
        root.history = root.history.filter(entry => entry.key !== item.key);
        root.save();
    }

    function clear() {
        for (const entry of root.history)
            root.live(entry.id)?.dismiss();
        root.history = [];
        root.unread = 0;
        root.save();
    }

    function markRead() {
        if (root.unread === 0)
            return;
        root.unread = 0;
        root.save();
    }

    function toggleDoNotDisturb() {
        root.doNotDisturb = !root.doNotDisturb;
        root.save();
    }

    // Theme icon names, absolute paths and URLs (image:// for pixel data) all occur.
    function iconSource(icon: string): string {
        if (icon === "")
            return "";
        if (icon.startsWith("/"))
            return "file://" + icon;
        if (/^[a-z]+:/.test(icon))
            return icon;
        return Quickshell.iconPath(icon, true);
    }

    function fallbackIcon(urgency: int): string {
        return Quickshell.iconPath(urgency === NotificationUrgency.Critical ? "dialog-warning" : "dialog-information", true);
    }

    function ago(time: real, now: real): string {
        const minutes = Math.floor((now - time) / 60000);
        if (minutes < 1)
            return "Just now";
        if (minutes < 60)
            return `${minutes} min ago`;
        if (minutes < 24 * 60)
            return `${Math.floor(minutes / 60)} h ago`;
        return Qt.formatDateTime(new Date(time), "d MMM hh:mm");
    }

    function record(notification: Notification) {
        // Pixel data is served from memory and dies with the notification.
        const image = notification.image.startsWith("/") || notification.image.startsWith("file:") ? notification.image : "";
        const entry = {
            key: `${Date.now()}-${notification.id}`,
            id: notification.id,
            appName: notification.appName,
            summary: notification.summary,
            body: notification.body,
            icon: image || notification.appIcon,
            urgency: notification.urgency,
            time: Date.now()
        };
        // Ids restart with the process, so an older entry with this id belongs to a dead notification.
        const older = root.history.map(item => item.id === notification.id ? Object.assign({}, item, {
                id: 0
            }) : item);
        const next = [entry, ...older];
        for (const evicted of next.slice(root.limit))
            root.live(evicted.id)?.dismiss();
        root.history = next.slice(0, root.limit);
        root.unread += 1;
        root.save();
    }

    function save() {
        file.setText(JSON.stringify({
            doNotDisturb: root.doNotDisturb,
            unread: root.unread,
            history: root.history
        }));
    }

    FileView {
        id: file

        path: Quickshell.env("HOME") + "/.local/state/temple/notifications.json"
        blockLoading: true
        printErrors: false
        onLoaded: {
            const state = JSON.parse(text());
            root.doNotDisturb = state.doNotDisturb ?? false;
            root.unread = state.unread ?? 0;
            root.history = state.history ?? [];
        }
    }

    NotificationServer {
        id: server

        keepOnReload: true
        actionsSupported: true
        imageSupported: true
        onNotification: notification => {
            notification.tracked = true;
            // A reload hands back the notifications the history already holds.
            if (notification.lastGeneration)
                return;
            root.record(notification);
            if (!root.doNotDisturb)
                root.popupRequested(notification);
            else if (notification.transient)
                notification.expire();
        }
    }
}
