import QtQuick
import QtQuick.Controls
import QtQuick.Window
import "../../modules/sddm" as Theme

// Interaction preview of the real Main.qml against a mocked SDDM.
// F1 forgets or restores the remembered user (a fresh install remembers none),
// F2 cycles the account list (two, one, none, five), F3 toggles Caps Lock,
// F4 toggles sleep support. Any password fails; the greeter logs to stdout.
Window {
    id: window
    width: 1280
    height: 800
    visible: true
    title: "Temple SDDM interaction preview"

    readonly property var people: ({
            temple: "Temple Explorer",
            guest: "Guest",
            ada: "Ada Lovelace",
            grace: "Grace Hopper",
            linus: "A user with an exceedingly long display name"
        })
    readonly property var accountSets: ["temple guest", "temple", "", "temple ada grace linus guest"]
    property int accounts: 0
    property bool remembered: true

    function reload() {
        screen.active = false;
        userModel.clear();
        for (const name of accountSets[accounts].split(" ").filter(entry => entry.length > 0))
            userModel.append({
                name: name,
                realName: people[name],
                icon: ""
            });
        userModel.lastUser = remembered && userModel.count > 0 ? userModel.get(0).name : "";
        screen.active = true;
    }

    Component.onCompleted: reload()
    Shortcut {
        sequence: "F1"
        onActivated: {
            window.remembered = !window.remembered;
            window.reload();
        }
    }
    Shortcut {
        sequence: "F2"
        onActivated: {
            window.accounts = (window.accounts + 1) % window.accountSets.length;
            window.reload();
        }
    }
    Shortcut {
        sequence: "F3"
        onActivated: keyboard.capsLock = !keyboard.capsLock
    }
    Shortcut {
        sequence: "F4"
        onActivated: sddm.canSuspend = !sddm.canSuspend
    }

    ListModel {
        id: userModel
        property string lastUser: ""
    }
    ListModel {
        id: sessionModel
        property int lastIndex: 0
        ListElement {
            name: "Temple"
        }
        ListElement {
            name: "Plasma (Wayland)"
        }
        ListElement {
            name: "GNOME"
        }
    }
    QtObject {
        id: keyboard
        property bool capsLock: false
        property var layouts: [
            {
                longName: "English (US)"
            },
            {
                longName: "Dutch"
            }
        ]
        property int currentLayout: 0
    }
    QtObject {
        id: sddm
        property bool canSuspend: true
        property bool canPowerOff: true
        property bool canReboot: true
        signal loginFailed
        signal loginSucceeded
        signal informationMessage(string message)
        function login(name, password, session) {
            console.log("AUTH", name, session);
            failure.restart();
        }
        function suspend() {
            console.log("SUSPEND");
        }
        function powerOff() {
            console.log("POWER OFF");
        }
        function reboot() {
            console.log("REBOOT");
        }
    }
    Timer {
        id: failure
        interval: 300
        onTriggered: sddm.loginFailed()
    }
    Loader {
        id: screen
        anchors.fill: parent
        active: false
        sourceComponent: Theme.Main {}
    }
}
