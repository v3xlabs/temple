pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// The wallpaper every screen shows. The choice lives in two places: the
// symlink the lock screen reads, and a text file QML can read back, since QML cannot
// resolve a symlink target.
Singleton {
    id: root

    readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/temple"
    // The user's own wallpapers, then the default wallpapers of the imitated systems.
    readonly property var wallpaperDirs: [Quickshell.env("HOME") + "/Pictures/Wallpapers", "/etc/temple/wallpapers"]

    property var backgrounds: []
    property var wallpapers: []
    readonly property var all: backgrounds.concat(wallpapers.filter(path => !backgrounds.includes(path)))

    property string chosen: ""
    property string preview: ""
    readonly property string effective: preview || chosen

    function choose(path: string) {
        preview = "";
        chosen = path;
        chosenFile.setText(path + "\n");
        Quickshell.execDetached(["ln", "-sfn", path, stateDir + "/background"]);
    }

    function previewPath(path: string) {
        preview = path;
    }

    function cancelPreview() {
        preview = "";
    }

    function rescan() {
        scan.running = true;
    }

    FileView {
        path: Quickshell.env("TEMPLE_BACKGROUNDS") || "/etc/temple/backgrounds.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.backgrounds = JSON.parse(text())
    }

    FileView {
        id: chosenFile

        path: root.stateDir + "/background.path"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.chosen = text().trim()
        onLoadFailed: root.chosen = ""
    }

    Process {
        id: scan

        running: true
        command: ["find", "-L", ...root.wallpaperDirs, "-maxdepth", "1", "-type", "f", "(", "-iname", "*.jpg", "-o", "-iname", "*.jpeg", "-o", "-iname", "*.png", "-o", "-iname", "*.webp", ")"]
        stdout: StdioCollector {
            onStreamFinished: {
                const found = text.split("\n").filter(line => line.length > 0).sort();
                let ordered = [];
                for (let i = 0; i < root.wallpaperDirs.length; i++)
                    ordered = ordered.concat(found.filter(path => path.startsWith(root.wallpaperDirs[i] + "/")));
                root.wallpapers = ordered;
            }
        }
    }
}
