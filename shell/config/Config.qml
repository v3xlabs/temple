pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Shell settings the NixOS module writes to /etc/temple/shell.json.
Singleton {
    id: root

    property var data: ({})

    readonly property var barMonitors: data.bar?.monitors ?? ({})
    readonly property bool activateLinux: data.activateLinux?.enable ?? false
    readonly property var activateLinuxMonitors: data.activateLinux?.monitors ?? []

    FileView {
        path: Quickshell.env("TEMPLE_SHELL_CONFIG") || "/etc/temple/shell.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.data = JSON.parse(text())
    }
}
