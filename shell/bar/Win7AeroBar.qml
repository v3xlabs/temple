import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland
import "../theme"
import "../activate"
import "../notifications"
import "../tray"
import "../windows"

PanelWindow {
    id: bar

    signal startRequested

    property bool startOpen: false

    readonly property var tokens: Theme.barTokens.win7
    // Theme JSON strings need color conversion before Qt.alpha.
    readonly property color tint: bar.tokens.tint
    readonly property color textColor: bar.tokens.text

    FontLoader {
        id: taskbarFont
        source: "assets/win7-segoe-ui.ttf"
    }

    WlrLayershell.namespace: "temple-bar"

    anchors {
        bottom: true
        left: true
        right: true
    }
    implicitHeight: bar.tokens.height
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(bar.tint, bar.tokens.opacity)

        BorderImage {
            anchors.fill: parent
            source: "assets/win7-taskbar.png"
            border.top: 2
            smooth: false
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 0
        anchors.rightMargin: showDesktop.width
        spacing: 0

        Item {
            id: start

            Layout.preferredWidth: 54
            Layout.fillHeight: true

            // Native frames retain transparent padding for the hover glow.
            Image {
                anchors.centerIn: parent
                width: 54
                height: 54
                source: "assets/win7-start-" + (bar.startOpen || startMouse.pressed ? "pressed" : startMouse.containsMouse ? "hover" : "normal") + ".png"
                smooth: false
            }

            MouseArea {
                id: startMouse

                anchors.fill: parent
                hoverEnabled: true
                onClicked: bar.startRequested()
            }
        }

        Row {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 4
            spacing: 2

            Repeater {
                model: ScriptModel {
                    values: Windows.windows.filter(toplevel => toplevel.monitor?.name === bar.screen.name)
                }

                BorderImage {
                    id: task

                    required property HyprlandToplevel modelData

                    readonly property int frame: (task.modelData.activated ? 4 : 1) + (taskMouse.pressed ? 2 : taskMouse.containsMouse ? 1 : 0)

                    width: 60
                    height: bar.height
                    source: "assets/win7-task-" + task.frame + ".png"
                    border.left: 3
                    border.right: 3
                    border.top: 3
                    border.bottom: 3
                    smooth: false

                    IconImage {
                        anchors.centerIn: parent
                        implicitSize: 32
                        source: Windows.icon(task.modelData)
                        opacity: Windows.minimized(task.modelData) ? 0.5 : 1
                    }

                    MouseArea {
                        id: taskMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                        onClicked: mouse => {
                            if (mouse.button === Qt.MiddleButton)
                                task.modelData.wayland?.close();
                            else
                                Windows.click(task.modelData);
                        }
                    }
                }
            }
        }

        Row {
            Layout.alignment: Qt.AlignVCenter
            Layout.rightMargin: 4
            spacing: 8

            NotificationBell {
                anchors.verticalCenter: parent.verticalCenter
                size: 16
            }

            Network {
                anchors.verticalCenter: parent.verticalCenter
                size: 16
            }

            Volume {
                anchors.verticalCenter: parent.verticalCenter
                size: 16
            }

            ActivateToggle {
                anchors.verticalCenter: parent.verticalCenter
            }

            Repeater {
                model: SystemTray.items

                Item {
                    id: trayItem

                    required property SystemTrayItem modelData

                    width: 24
                    height: bar.height

                    IconImage {
                        anchors.centerIn: parent
                        implicitSize: 16
                        source: trayItem.modelData.icon
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                        onClicked: mouse => {
                            const item = trayItem.modelData;
                            if (mouse.button === Qt.MiddleButton) {
                                item.secondaryActivate();
                            } else if (mouse.button === Qt.LeftButton && !item.onlyMenu) {
                                item.activate();
                            } else if (item.hasMenu) {
                                const position = trayItem.mapToItem(null, 0, 0);
                                item.display(bar, position.x, position.y);
                            }
                        }
                        onWheel: wheel => trayItem.modelData.scroll(wheel.angleDelta.y, false)
                    }
                }
            }
        }

        Item {
            id: clockArea

            Layout.fillHeight: true
            Layout.preferredWidth: Math.max(timeLabel.implicitWidth, dateLabel.implicitWidth) + 9

            BorderImage {
                anchors.fill: parent
                source: "assets/win7-clock-" + (clockMouse.pressed ? "pressed" : clockMouse.containsMouse ? "hover" : "normal") + ".png"
                border.left: 2
                border.right: 2
                border.top: 14
                border.bottom: 14
                smooth: false
            }

            Column {
                anchors.centerIn: parent

                Text {
                    id: timeLabel
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(clock.date, "h:mm AP")
                    color: bar.textColor
                    font.family: taskbarFont.name
                    font.pixelSize: 12
                    font.hintingPreference: Font.PreferFullHinting
                    renderType: Text.NativeRendering
                }

                Text {
                    id: dateLabel
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(clock.date, "M/d/yyyy")
                    color: bar.textColor
                    font.family: taskbarFont.name
                    font.pixelSize: 12
                    font.hintingPreference: Font.PreferFullHinting
                    renderType: Text.NativeRendering
                }
            }

            MouseArea {
                id: clockMouse
                anchors.fill: parent
                hoverEnabled: true
            }
        }
    }

    BorderImage {
        id: showDesktop

        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 17
        source: "assets/win7-desktop-" + (showDesktopMouse.pressed ? "pressed" : showDesktopMouse.containsMouse ? "hover" : "normal") + ".png"
        border.left: 2
        border.right: 2
        border.top: 15
        border.bottom: 2
        smooth: false

        MouseArea {
            id: showDesktopMouse

            anchors.fill: parent
            hoverEnabled: true
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
