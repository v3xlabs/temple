pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "../theme"
import "../apps"
import "../session"

PanelWindow {
    id: root

    property bool open: false
    property string action: "shutdown"
    // 0 = primary button, 1 = Cancel. Enter presses the focused one.
    property int focusedButton: 0

    readonly property var texts: ({
            shutdown: {
                title: "Shut down",
                question: "Shut down this computer?",
                button: "Shut down",
                icon: "system-shutdown",
                orb: "#c42b1c"
            },
            reboot: {
                title: "Restart",
                question: "Restart this computer?",
                button: "Restart",
                icon: "system-reboot",
                orb: "#3a8f2e"
            },
            logout: {
                title: "Log off",
                question: "Log off " + Session.user + "?",
                button: "Log off",
                icon: "system-log-out",
                orb: "#d98a1b"
            },
            suspend: {
                title: "Sleep",
                question: "Put this computer to sleep?",
                button: "Sleep",
                icon: "system-suspend",
                orb: "#3a96dd"
            }
        })
    readonly property var current: texts[action] ?? texts.shutdown
    readonly property color tint: Theme.barTokens.win7.tint

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
    color: "#99000000"

    // Modal: clicks beside the dialog do nothing.
    MouseArea {
        anchors.fill: parent
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
    }

    Rectangle {
        id: frame

        anchors.centerIn: parent
        width: 420
        height: 170
        radius: 6
        color: Qt.alpha(root.tint, 0.92)
        border.width: 1
        border.color: "#40ffffff"

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 1
            height: 30
            radius: 5
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: Qt.lighter(root.tint, 2.2)
                }
                GradientStop {
                    position: 0.5
                    color: Qt.lighter(root.tint, 1.5)
                }
                GradientStop {
                    position: 1
                    color: root.tint
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: parent.height / 2
                radius: 5
                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: "#30ffffff"
                    }
                    GradientStop {
                        position: 1
                        color: "#08ffffff"
                    }
                }
            }
        }

        Text {
            x: 10
            y: 0
            height: 30
            verticalAlignment: Text.AlignVCenter
            text: root.current.title
            color: "#ffffff"
            style: Text.Raised
            styleColor: "#80000000"
            font.family: Theme.fontSans
            font.pixelSize: Theme.fontSize
        }

        Rectangle {
            id: close

            anchors.right: parent.right
            anchors.rightMargin: 6
            anchors.top: parent.top
            anchors.topMargin: 1
            width: 43
            height: 19
            radius: 3
            border.width: 1
            border.color: "#80300a00"
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: closeMouse.containsMouse ? "#f4b8a8" : "#e2a08e"
                }
                GradientStop {
                    position: 0.45
                    color: closeMouse.containsMouse ? "#e85a3c" : "#c9472e"
                }
                GradientStop {
                    position: 1
                    color: closeMouse.containsMouse ? "#f07a50" : "#d6633f"
                }
            }

            Repeater {
                model: [45, -45]

                Rectangle {
                    required property int modelData

                    anchors.centerIn: parent
                    width: 11
                    height: 2
                    radius: 1
                    rotation: modelData
                    color: "#ffffff"
                    antialiasing: true
                }
            }

            MouseArea {
                id: closeMouse

                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.cancel()
            }
        }

        Rectangle {
            id: content

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.margins: 6
            anchors.topMargin: 31
            radius: 2
            color: "#1c2733"
            border.width: 1
            border.color: "#0a0f16"
            clip: true

            // Breeze action icons are dark line art, so they sit on a glossy orb
            // that stays readable on the dark dialog.
            Rectangle {
                id: icon

                x: 18
                y: (strip.y - height) / 2
                width: 48
                height: 48
                radius: 24
                border.width: 1
                border.color: Qt.darker(root.current.orb, 1.6)
                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: Qt.lighter(root.current.orb, 1.5)
                    }
                    GradientStop {
                        position: 1
                        color: root.current.orb
                    }
                }

                IconImage {
                    anchors.centerIn: parent
                    implicitSize: 28
                    source: Apps.iconSource(root.current.icon)
                }
            }

            Text {
                anchors.left: icon.right
                anchors.leftMargin: 16
                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.verticalCenter: icon.verticalCenter
                text: root.current.question
                wrapMode: Text.Wrap
                color: "#7eb4ea"
                font.family: Theme.fontSans
                font.pixelSize: Theme.fontSize + 3
            }

            Rectangle {
                id: strip

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 1
                height: 42
                color: "#16202b"

                Rectangle {
                    width: parent.width
                    height: 1
                    color: "#2a3646"
                }

                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Repeater {
                        model: [root.current.button, "Cancel"]

                        Rectangle {
                            id: button

                            required property string modelData
                            required property int index
                            readonly property bool focused: root.focusedButton === index

                            width: 86
                            height: 24
                            radius: 3
                            border.width: 1
                            border.color: button.focused ? Theme.accent : "#5c6f85"
                            gradient: Gradient {
                                GradientStop {
                                    position: 0
                                    color: buttonMouse.containsMouse ? "#4a5e74" : "#3a4a5c"
                                }
                                GradientStop {
                                    position: 1
                                    color: buttonMouse.containsMouse ? "#33435a" : "#2a3646"
                                }
                            }

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 1
                                radius: 2
                                color: "transparent"
                                border.width: 1
                                border.color: button.focused ? Qt.alpha(Theme.accent, 0.5) : "#18ffffff"
                            }

                            Text {
                                anchors.centerIn: parent
                                text: button.modelData
                                color: "#e8eef5"
                                font.family: Theme.fontSans
                                font.pixelSize: Theme.fontSize
                            }

                            MouseArea {
                                id: buttonMouse

                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: button.index === 0 ? root.confirm() : root.cancel()
                            }
                        }
                    }
                }
            }
        }
    }
}
