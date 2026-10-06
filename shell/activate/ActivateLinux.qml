pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../config"

// The "Activate Linux" watermark. Off at login; the bar icon or IPC turns it on.
Singleton {
    id: root

    readonly property bool shown: Config.activateLinux && state.shown

    function toggle() {
        state.shown = !state.shown;
    }

    PersistentProperties {
        id: state

        reloadableId: "activateLinux"

        property bool shown: false
    }

    IpcHandler {
        target: "activateLinux"

        function toggle(): bool {
            root.toggle();
            return root.shown;
        }
    }
}
