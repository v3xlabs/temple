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

    property string mode: "shutdown"
    property bool open: false

    function show(target: ShellScreen, newMode: string) {
        screen = target;
        mode = newMode;
        open = true;
        focusScope.forceActiveFocus();
    }

    function cancel() {
        open = false;
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
    color: "#80808080"

    component ActionButton: Item {
        id: action

        property string label
        property string icon
        property color tint

        signal activated

        width: 72
        height: 64

        Rectangle {
            id: face

            anchors.horizontalCenter: parent.horizontalCenter
            width: 34
            height: 34
            radius: 17
            antialiasing: true
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.8)
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: Qt.lighter(action.tint, actionArea.containsMouse ? 1.5 : 1.3)
                }
                GradientStop {
                    position: 1
                    color: actionArea.containsMouse ? Qt.lighter(action.tint, 1.15) : action.tint
                }
            }

            IconImage {
                anchors.centerIn: parent
                implicitSize: 22
                source: Apps.iconSource(action.icon)
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: face.bottom
            anchors.topMargin: 6
            text: action.label
            color: "#ffffff"
            font.family: Theme.fontSans
            font.pixelSize: Theme.fontSize
        }

        MouseArea {
            id: actionArea

            anchors.fill: parent
            hoverEnabled: true
            onClicked: action.activated()
        }
    }

    MouseArea {
        anchors.fill: parent
    }

    FocusScope {
        id: focusScope

        anchors.fill: parent
        Keys.onEscapePressed: root.cancel()
    }

    Rectangle {
        anchors.centerIn: parent
        width: 312
        height: 200
        color: "#00309c"
        border.width: 1
        border.color: "#001f6b"

        Item {
            id: titleBand

            x: 1
            y: 1
            width: parent.width - 2
            height: 44

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: root.mode === "logoff" ? "Log Off Windows" : "Turn off computer"
                color: "#ffffff"
                font.family: Theme.fontSans
                font.pixelSize: Theme.fontSize + 5
            }

            Grid {
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                columns: 2
                spacing: 1

                // Logo colours of the flag mark, intentionally independent of the theme palette.
                Repeater {
                    model: ["#f25022", "#7fba00", "#00a4ef", "#ffb900"]

                    Rectangle {
                        id: pane

                        required property color modelData

                        width: 10
                        height: 10
                        radius: 2
                        antialiasing: true
                        color: pane.modelData
                    }
                }
            }
        }

        Rectangle {
            id: actionBand

            x: 1
            anchors.top: titleBand.bottom
            width: parent.width - 2
            height: 110
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: "#5a7edc"
                }
                GradientStop {
                    position: 1
                    color: "#2752b9"
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: "#7d9ce6"
            }

            Row {
                anchors.centerIn: parent
                spacing: 16

                ActionButton {
                    visible: root.mode === "shutdown"
                    label: "Stand By"
                    icon: "system-suspend"
                    tint: "#f5c242"
                    onActivated: {
                        root.cancel();
                        Session.suspend();
                    }
                }

                ActionButton {
                    visible: root.mode === "shutdown"
                    label: "Turn Off"
                    icon: "system-shutdown"
                    tint: "#d9432f"
                    onActivated: {
                        root.cancel();
                        Session.shutdown();
                    }
                }

                ActionButton {
                    visible: root.mode === "shutdown"
                    label: "Restart"
                    icon: "system-reboot"
                    tint: "#3ba32b"
                    onActivated: {
                        root.cancel();
                        Session.reboot();
                    }
                }

                ActionButton {
                    visible: root.mode === "logoff"
                    label: "Lock"
                    icon: "system-lock-screen"
                    tint: "#3ba32b"
                    onActivated: {
                        root.cancel();
                        Session.lock();
                    }
                }

                ActionButton {
                    visible: root.mode === "logoff"
                    label: "Log Off"
                    icon: "system-log-out"
                    tint: "#e8a21b"
                    onActivated: {
                        root.cancel();
                        Session.logout();
                    }
                }
            }
        }

        Rectangle {
            id: cancelButton

            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 12
            width: 76
            height: 23
            radius: 3
            antialiasing: true
            border.width: 1
            border.color: cancelArea.containsMouse ? "#e5a836" : "#003c74"
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: "#ffffff"
                }
                GradientStop {
                    position: 0.85
                    color: "#ecebe6"
                }
                GradientStop {
                    position: 1
                    color: "#d6d0c5"
                }
            }

            Text {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: cancelArea.pressed ? 1 : 0
                text: "Cancel"
                color: "#000000"
                font.family: Theme.fontSans
                font.pixelSize: Theme.fontSize
            }

            MouseArea {
                id: cancelArea

                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.cancel()
            }
        }
    }
}
