pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

// Taskbar actions. Minimizing lives in the Hyprland config (temple.minimize).
Singleton {
    id: root

    // Window addresses, most recently focused first.
    property var recent: []

    function minimized(toplevel: HyprlandToplevel): bool {
        return toplevel.workspace?.name === "special:minimized";
    }

    // Windows taskbar click: a minimized window comes back, the focused one
    // minimizes, any other window gets focus.
    function click(toplevel: HyprlandToplevel) {
        if (toplevel.activated && !minimized(toplevel))
            Quickshell.execDetached(["hyprctl", "eval", `temple.minimize("${toplevel.address}")`]);
        else
            focus(toplevel);
    }

    function focus(toplevel: HyprlandToplevel) {
        const call = minimized(toplevel) ? `temple.restore("${toplevel.address}")` : `temple.focus("${toplevel.address}")`;
        Quickshell.execDetached(["hyprctl", "eval", call]);
    }

    // Hyprland also tracks windows that are not on screen, such as hidden
    // helper windows. Only mapped windows get a toplevel handle, so the handle
    // marks the windows a user can see; the IPC fields catch the rest.
    function real(toplevel: HyprlandToplevel): bool {
        const ipc = toplevel.lastIpcObject;
        return toplevel.wayland !== null && ipc.mapped !== false && ipc.hidden !== true && toplevel.title !== "";
    }

    readonly property var windows: Hyprland.toplevels.values.filter(real)

    function byRecentUse() {
        const rank = address => {
            const index = recent.indexOf(address);
            return index < 0 ? recent.length : index;
        };
        return windows.slice().sort((a, b) => rank(a.address) - rank(b.address));
    }

    Connections {
        target: Hyprland
        function onActiveToplevelChanged() {
            const address = Hyprland.activeToplevel?.address;
            if (address)
                root.recent = [address, ...root.recent.filter(other => other !== address)];
        }
    }

    function icon(toplevel: HyprlandToplevel): string {
        const appId = toplevel.wayland?.appId ?? toplevel.lastIpcObject.class ?? "";
        return Quickshell.iconPath(DesktopEntries.heuristicLookup(appId)?.icon ?? "", "application-x-executable");
    }
}
