pragma Singleton
import QtQuick
import Quickshell

// Ending or pausing the session. Callers confirm first; these act at once.
// ksmserver ends the Plasma session cleanly before it powers off or reboots.
Singleton {
    readonly property string user: Quickshell.env("USER") ?? ""

    function shutdown() {
        ksmserver("logoutAndShutdown");
    }

    function reboot() {
        ksmserver("logoutAndReboot");
    }

    function suspend() {
        Quickshell.execDetached(["systemctl", "suspend"]);
    }

    function logout() {
        ksmserver("logout");
    }

    function lock() {
        Quickshell.execDetached(["busctl", "--user", "call", "org.freedesktop.ScreenSaver", "/ScreenSaver", "org.freedesktop.ScreenSaver", "Lock"]);
    }

    function ksmserver(method: string) {
        Quickshell.execDetached(["busctl", "--user", "call", "org.kde.Shutdown", "/Shutdown", "org.kde.Shutdown", method]);
    }
}
