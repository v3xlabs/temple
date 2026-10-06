pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Programs the launchers offer: Temple's commands and the installed applications.
Singleton {
    id: root

    property var commands: []
    // Desktop entry ids, most recently launched first. Kept across sessions.
    property var recent: []

    readonly property var applications: DesktopEntries.applications.values.filter(app => !app.noDisplay).sort((a, b) => a.name.localeCompare(b.name))
    readonly property var recentApplications: recent.map(id => DesktopEntries.byId(id)).filter(app => app !== null && !app.noDisplay)

    function launch(app: DesktopEntry) {
        app.execute();
        recent = [app.id, ...recent.filter(id => id !== app.id)].slice(0, 12);
        recentFile.setText(JSON.stringify(recent));
    }

    function run(command) {
        Quickshell.execDetached(command.exec);
    }

    // Desktop entries name an icon from the theme or give an absolute path.
    function iconSource(icon: string): string {
        return icon.startsWith("/") ? "file://" + icon : Quickshell.iconPath(icon, "application-x-executable");
    }

    FileView {
        path: Quickshell.env("TEMPLE_COMMANDS") || "/etc/temple/commands.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.commands = JSON.parse(text())
    }

    FileView {
        id: recentFile

        path: Quickshell.env("HOME") + "/.local/state/temple/recent-apps.json"
        onLoaded: root.recent = JSON.parse(text())
    }
}
