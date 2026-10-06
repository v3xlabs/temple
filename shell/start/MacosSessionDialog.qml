pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "../apps"
import "../macos"
import "../session"

// The macOS alert that asks before the session ends: icon, bold question,
// Cancel and the default button side by side. Return confirms, Escape cancels.
PanelWindow {
    id: root

    property bool open: false
    property string action: "shutdown"

    readonly property var texts: ({
            shutdown: {
                question: "Are you sure you want to shut down your computer now?",
                button: "Shut Down",
                icon: "system-shutdown"
            },
            reboot: {
                question: "Are you sure you want to restart your computer now?",
                button: "Restart",
                icon: "system-reboot"
            },
            logout: {
                question: "Are you sure you want to quit all applications and log out now?",
                button: "Log Out",
                icon: "system-log-out"
            },
            suspend: {
                question: "Are you sure you want to put your computer to sleep now?",
                button: "Sleep",
                icon: "system-suspend"
            }
        })
    readonly property var current: texts[action] ?? texts.shutdown

    function show(target: ShellScreen, action: string) {
        screen = target;
        root.action = action;
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

    // Modal: clicks beside the alert do nothing.
    MouseArea {
        anchors.fill: parent
    }

    Item {
        id: keys

        anchors.fill: parent
        Keys.onEscapePressed: root.cancel()
        Keys.onReturnPressed: root.confirm()
        Keys.onEnterPressed: root.confirm()
    }

    Glass {
        id: alert

        readonly property int inset: Math.max(16, Math.round(Macos.dialogRadius * 0.75))

        anchors.centerIn: parent
        width: 260
        height: content.implicitHeight + alert.inset * 2
        radius: Macos.dialogRadius
        tintOpacity: Math.max(Macos.panelOpacity, 0.9)
        shadow: true

        Column {
            id: content

            x: alert.inset
            y: alert.inset
            width: alert.width - alert.inset * 2
            spacing: 10

            IconImage {
                anchors.horizontalCenter: parent.horizontalCenter
                implicitSize: 64
                source: Apps.iconSource(root.current.icon)
            }

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: root.current.question
                wrapMode: Text.Wrap
                color: Macos.panelText
                font.family: Macos.font
                font.pixelSize: Macos.fontSize
                font.weight: Font.Bold
            }

            Item {
                width: 1
                height: 4
            }

            Row {
                width: parent.width
                spacing: 8

                Repeater {
                    model: ["Cancel", root.current.button]

                    Rectangle {
                        id: button

                        required property string modelData
                        required property int index
                        readonly property bool primary: index === 1

                        width: (content.width - 8) / 2
                        height: 28
                        radius: Math.min(height / 2, Macos.selectionRadius + 2)
                        color: button.primary ? Macos.selection : buttonMouse.pressed ? "#26000000" : "#14000000"
                        border.width: button.primary ? 0 : 1
                        border.color: "#0f000000"

                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            visible: button.primary && buttonMouse.pressed
                            color: "#26000000"
                        }

                        Text {
                            anchors.centerIn: parent
                            text: button.modelData
                            color: button.primary ? Macos.selectionText : Macos.panelText
                            font.family: Macos.font
                            font.pixelSize: Macos.fontSize
                            font.weight: Font.Medium
                        }

                        MouseArea {
                            id: buttonMouse

                            anchors.fill: parent
                            onClicked: button.primary ? root.confirm() : root.cancel()
                        }
                    }
                }
            }
        }
    }
}
