pragma Singleton
import QtQuick
import Quickshell
import org.kde.taskmanager as TaskManager

// The windows on the current virtual desktop, from the task model Plasma's own
// taskbar uses. KWin shares it only with binaries a desktop file grants
// org_kde_plasma_window_management, which the NixOS module installs.
Singleton {
    id: root

    property list<QtObject> windows: []
    readonly property QtObject active: windows.find(window => window.activated) ?? null
    // KWin keeps the keyboard focus to itself, so the active window's screen
    // stands in for it. An overlay that takes the keyboard leaves no window
    // active; falling back to another screen then would move that overlay,
    // which hands the focus back and moves it again, so the last screen stays.
    readonly property ShellScreen activeScreen: active?.screen ?? null
    property ShellScreen lastScreen: null
    readonly property ShellScreen focusedScreen: activeScreen ?? lastScreen ?? Quickshell.screens[0]

    onActiveScreenChanged: {
        if (activeScreen !== null)
            lastScreen = activeScreen;
    }

    // Windows taskbar click: a minimized window comes back, the focused one
    // minimizes, any other window gets focus.
    function click(window: QtObject) {
        if (window.activated && !window.minimized)
            tasks.requestToggleMinimized(tasks.makeModelIndex(window.row));
        else
            focus(window);
    }

    // Activating a minimized window restores it.
    function focus(window: QtObject) {
        tasks.requestActivate(tasks.makeModelIndex(window.row));
    }

    function close(window: QtObject) {
        tasks.requestClose(tasks.makeModelIndex(window.row));
    }

    function entry(window: QtObject): DesktopEntry {
        return DesktopEntries.byId(window.desktopId) ?? DesktopEntries.heuristicLookup(window.appId);
    }

    function icon(window: QtObject): string {
        return Quickshell.iconPath(entry(window)?.icon ?? "", "application-x-executable");
    }

    TaskManager.TasksModel {
        id: tasks

        groupMode: TaskManager.TasksModel.GroupDisabled
        sortMode: TaskManager.TasksModel.SortDisabled
        filterByVirtualDesktop: true
        filterByActivity: true
    }

    Instantiator {
        model: tasks

        delegate: QtObject {
            required property var model
            required property int index

            readonly property int row: index
            readonly property string title: model.display ?? ""
            readonly property string appId: model.AppId ?? ""
            // applications:org.kde.konsole.desktop for windows KDE matched to a desktop file.
            readonly property string desktopId: String(model.LauncherUrlWithoutIcon ?? "").replace(/^applications:/, "").replace(/\.desktop$/, "")
            readonly property bool activated: model.IsActive
            readonly property bool minimized: model.IsMinimized
            readonly property ShellScreen screen: {
                const geometry = model.ScreenGeometry;
                return Quickshell.screens.find(screen => screen.x === geometry.x && screen.y === geometry.y) ?? null;
            }
        }

        onObjectAdded: (index, object) => {
            const windows = Array.from(root.windows);
            windows.splice(index, 0, object);
            root.windows = windows;
        }
        onObjectRemoved: (index, object) => root.windows = Array.from(root.windows).filter(window => window !== object)
    }
}
