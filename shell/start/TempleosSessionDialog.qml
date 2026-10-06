pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../session"

// PopUpNoYes from Adam/DolDoc/DocPopUp.HC: a text window with the question and
// a YES and a NO button, each in a single-line text border. The focused button
// gets the double border.
PanelWindow {
    id: root

    property bool open: false
    property string action: "shutdown"
    // 0 = YES, 1 = NO. Enter presses the focused one.
    property int focusedButton: 0

    readonly property var texts: ({
            shutdown: {
                title: "Shut down",
                question: "Shut down the computer?"
            },
            reboot: {
                title: "Reboot",
                question: "Reboot the computer?"
            },
            logout: {
                title: "Log out",
                question: "Log out " + Session.user + "?"
            },
            suspend: {
                title: "Suspend",
                question: "Suspend the computer?"
            }
        })
    readonly property var current: texts[action] ?? texts.shutdown
    readonly property real cell: metrics.averageCharacterWidth
    readonly property real line: metrics.height

    function show(target: ShellScreen, action: string) {
        screen = target;
        root.action = action;
        focusedButton = 0;
        open = true;
        keys.forceActiveFocus();
    }

    function cancel() {
        open = false;
    }

    function confirm() {
        open = false;
        if (action === "shutdown")
            Session.shutdown();
        else if (action === "reboot")
            Session.reboot();
        else if (action === "logout")
            Session.logout();
        else if (action === "suspend")
            Session.suspend();
    }

    visible: open
    WlrLayershell.namespace: "temple-session-dialog"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"

    // Modal: clicks beside the dialog do nothing.
    MouseArea {
        anchors.fill: parent
    }

    FontMetrics {
        id: metrics

        font.family: Theme.fontSans
        font.pixelSize: Theme.fontSize
    }

    Item {
        id: keys

        anchors.fill: parent
        Keys.onEscapePressed: root.cancel()
        Keys.onReturnPressed: root.focusedButton === 0 ? root.confirm() : root.cancel()
        Keys.onEnterPressed: root.focusedButton === 0 ? root.confirm() : root.cancel()
        Keys.onTabPressed: root.focusedButton = 1 - root.focusedButton
        Keys.onBacktabPressed: root.focusedButton = 1 - root.focusedButton
        Keys.onLeftPressed: root.focusedButton = 0
        Keys.onRightPressed: root.focusedButton = 1
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Y)
                root.confirm();
            else if (event.key === Qt.Key_N)
                root.cancel();
        }
    }

    TempleosFrame {
        id: window

        // Border, a blank column, the question, a blank column, border.
        readonly property int columns: Math.max(root.current.question.length, 16) + 4

        x: Math.round((parent.width - width) / 2 / root.cell) * root.cell
        y: Math.round((parent.height - height) / 2 / root.line) * root.line
        width: window.columns * root.cell
        height: 8 * root.line
        title: root.current.title

        Text {
            x: 2 * root.cell
            y: 2 * root.line
            text: root.current.question
            color: window.color
            font.family: Theme.fontSans
            font.pixelSize: Theme.fontSize
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 4 * root.line
            spacing: 3 * root.cell

            Button {
                label: "YES"
                index: 0
                onClicked: root.confirm()
            }

            Button {
                label: "NO"
                index: 1
                onClicked: root.cancel()
            }
        }
    }

    component Button: TempleosFrame {
        id: button

        property string label
        property int index

        signal clicked

        width: (button.label.length + 2) * root.cell
        height: 3 * root.line
        double: root.focusedButton === button.index

        Text {
            x: root.cell
            y: root.line
            text: button.label
            color: button.color
            font.family: Theme.fontSans
            font.pixelSize: Theme.fontSize
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: root.focusedButton = button.index
            onClicked: button.clicked()
        }
    }
}
