pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Watches the processor and the disks, and raises a warning when the processor
// stays saturated, a disk runs low on space, or a disk fills fast enough to run
// out soon. Each warning sends one notification when it starts.
Singleton {
    id: root

    // The processor counts as saturated while its load over the last `cpuWindow`
    // samples averages at least `cpuHigh`, and stops once it drops under `cpuClear`.
    readonly property int cpuInterval: 2000
    readonly property int cpuWindow: 5
    readonly property real cpuHigh: 0.98
    readonly property real cpuClear: 0.9
    // A disk is low on space under the smaller of these.
    readonly property real lowBytes: 20 * 1024 * 1024 * 1024
    readonly property real lowFraction: 0.1
    // A disk is filling when its growth over at least `rateWindow` ms would use
    // up the free space within `fillSoon` ms, and stops once that takes `fillClear` ms.
    readonly property int diskInterval: 10000
    readonly property int rateWindow: 30000
    readonly property int fillSoon: 10 * 60 * 1000
    readonly property int fillClear: 30 * 60 * 1000

    property var cpuSamples: []
    property var lastStat: null
    property bool cpuSaturated: false
    // Mount point to {source, size, avail, samples: [{time, used}], low, filling, rate}.
    property var disks: ({})

    readonly property real cpuLoad: cpuSamples.length > 0 ? cpuSamples.reduce((sum, sample) => sum + sample, 0) / cpuSamples.length : 0
    // One entry per active warning: {kind, title, body, target}.
    readonly property var warnings: {
        const list = [];
        if (root.cpuSaturated)
            list.push({
                kind: "cpu",
                title: `Processor at ${Math.round(root.cpuLoad * 100)}%`,
                body: `The processor has been busy for ${root.cpuWindow * root.cpuInterval / 1000} seconds or more.`,
                target: ""
            });
        for (const [target, disk] of Object.entries(root.disks)) {
            if (disk.filling)
                list.push({
                    kind: "filling",
                    title: `${target} is filling up`,
                    body: `${target} grows by ${root.size(disk.rate * 60000)} a minute and will be full in about ${root.minutes(disk.avail / disk.rate)}.`,
                    target
                });
            else if (disk.low)
                list.push({
                    kind: "low",
                    title: `${target} is ${Math.round(100 * (1 - disk.avail / disk.size))}% full`,
                    body: `Only ${root.size(disk.avail)} of ${root.size(disk.size)} is free on ${target} (${disk.source}).`,
                    target
                });
        }
        return list;
    }

    function size(bytes: real): string {
        const units = ["B", "KB", "MB", "GB", "TB"];
        let value = bytes;
        let unit = 0;
        while (value >= 1024 && unit < units.length - 1) {
            value /= 1024;
            unit += 1;
        }
        return `${value < 10 && unit > 0 ? value.toFixed(1) : Math.round(value)} ${units[unit]}`;
    }

    function minutes(ms: real): string {
        const count = Math.max(1, Math.round(ms / 60000));
        return count === 1 ? "a minute" : `${count} minutes`;
    }

    // Critical popups stay until dismissed, so only a disk about to run out is critical.
    function notify(title: string, body: string, critical: bool) {
        // The shell is the notification server, so the warning goes through the same popups, bell and Clippy.
        // `--` keeps busctl from reading the -1 timeout as an option.
        Quickshell.execDetached(["busctl", "--user", "call", "--", "org.freedesktop.Notifications", "/org/freedesktop/Notifications", "org.freedesktop.Notifications", "Notify", "susssasa{sv}i", "System Health", "0", "dialog-warning", title, body, "0", "1", "urgency", "y", critical ? "2" : "1", "-1"]);
    }

    function readStat(text: string) {
        const fields = text.slice(0, text.indexOf("\n")).trim().split(/\s+/).slice(1, 9).map(Number);
        const stat = {
            idle: fields[3] + fields[4],
            total: fields.reduce((sum, field) => sum + field, 0)
        };
        const last = lastStat;
        lastStat = stat;
        if (last === null || stat.total <= last.total)
            return;
        const busy = 1 - (stat.idle - last.idle) / (stat.total - last.total);
        cpuSamples = [...cpuSamples, busy].slice(-cpuWindow);
        if (!cpuSaturated && cpuSamples.length === cpuWindow && cpuLoad >= cpuHigh) {
            cpuSaturated = true;
            notify("High CPU usage", `The processor has been at ${Math.round(cpuLoad * 100)}% for ${cpuWindow * cpuInterval / 1000} seconds.`, false);
        } else if (cpuSaturated && cpuLoad < cpuClear) {
            cpuSaturated = false;
        }
    }

    // `df --output=source,size,used,avail,target`, header first. The mount point is the last column and may hold spaces.
    function readDisks(text: string) {
        const now = Date.now();
        const next = {};
        for (const line of text.trim().split("\n").slice(1)) {
            const parts = line.trim().split(/\s+/);
            const target = parts.slice(4).join(" ");
            const [source, total, used, avail] = [parts[0], Number(parts[1]), Number(parts[2]), Number(parts[3])];
            if (!(total > 0))
                continue;
            const before = disks[target];
            const samples = [...(before?.samples ?? []).filter(sample => now - sample.time <= 2 * rateWindow),
                {
                    time: now,
                    used
                }
            ];
            const oldest = samples[0];
            const rate = now - oldest.time >= rateWindow ? (used - oldest.used) / (now - oldest.time) : 0;
            const eta = rate > 0 ? avail / rate : Infinity;
            const threshold = Math.min(lowBytes, total * lowFraction);
            const disk = {
                source,
                size: total,
                avail,
                samples,
                rate,
                low: before?.low ? avail < threshold * 1.1 : avail < threshold,
                filling: before?.filling ? eta < fillClear : eta < fillSoon
            };
            if (disk.filling && !before?.filling)
                notify("Disk filling up", `${target} grows by ${size(rate * 60000)} a minute and will be full in about ${minutes(eta)}.`, true);
            else if (disk.low && !before?.low && !disk.filling)
                notify("Low Disk Space", `You are running out of disk space on ${target}: ${size(avail)} free.`, false);
            next[target] = disk;
        }
        disks = next;
    }

    FileView {
        id: stat

        path: "/proc/stat"
        onLoaded: root.readStat(text())
    }

    Timer {
        interval: root.cpuInterval
        running: true
        repeat: true
        onTriggered: stat.reload()
    }

    // Pseudo and memory filesystems are left out; df already drops repeated mounts of one device.
    Process {
        id: df

        command: ["df", "-B1", "--output=source,size,used,avail,target", "-x", "tmpfs", "-x", "devtmpfs", "-x", "ramfs", "-x", "efivarfs", "-x", "squashfs", "-x", "overlay"]
        stdout: StdioCollector {
            onStreamFinished: root.readDisks(text)
        }
    }

    Timer {
        interval: root.diskInterval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: df.running = true
    }
}
