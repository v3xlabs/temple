pragma Singleton
import QtQuick
import Quickshell

// Ending or pausing the session. Callers confirm first; these act at once.
Singleton {
    readonly property string user: Quickshell.env("USER") ?? ""

    function shutdown() {
        Quickshell.execDetached(["systemctl", "poweroff"]);
    }

    function reboot() {
        Quickshell.execDetached(["systemctl", "reboot"]);
    }

    function suspend() {
        Quickshell.execDetached(["systemctl", "suspend"]);
    }

    // uwsm stops the graphical session units before the compositor exits.
    function logout() {
        Quickshell.execDetached(["uwsm", "stop"]);
    }

    function lock() {
        Quickshell.execDetached(["temple-lock"]);
    }
}
