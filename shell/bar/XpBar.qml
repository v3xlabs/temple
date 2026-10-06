pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland
import "../theme"
import "../activate"
import "../tray"
import "../notifications"
import "../windows"

PanelWindow {
    id: bar

    signal startRequested

    readonly property var tokens: Theme.barTokens.xp

    function shaded(base, factor) {
        return factor >= 1 ? Qt.lighter(base, factor) : Qt.darker(base, 1 / factor);
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
        gradient: Gradient {
            GradientStop {
                position: 0
                color: bar.tokens.taskbarTop
            }
            GradientStop {
                position: 0.1
                color: bar.tokens.taskbarMid
            }
            GradientStop {
                position: 0.8
                color: bar.tokens.taskbarMid
            }
            GradientStop {
                position: 1
                color: bar.tokens.taskbarBottom
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Qt.lighter(bar.tokens.taskbarTop, 1.25)
        }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            Item {
                id: startButton

                readonly property real shade: startArea.pressed ? 0.85 : startArea.containsMouse ? 1.1 : 1
                readonly property int cornerRadius: 10

                Layout.fillHeight: true
                Layout.preferredWidth: startContent.implicitWidth + 30
                // Rounding only the right corners: the faces extend past the left edge and get clipped.
                clip: true

                Rectangle {
                    x: -startButton.cornerRadius
                    width: parent.width + startButton.cornerRadius
                    height: parent.height
                    radius: startButton.cornerRadius
                    antialiasing: true
                    color: Qt.darker(bar.tokens.startBottom, 1.5)
                }

                Rectangle {
                    x: -startButton.cornerRadius
                    width: parent.width + startButton.cornerRadius - 2
                    height: parent.height
                    radius: startButton.cornerRadius
                    antialiasing: true
                    gradient: Gradient {
                        GradientStop {
                            position: 0
                            color: bar.shaded(bar.tokens.startTop, startButton.shade)
                        }
                        GradientStop {
                            position: 0.45
                            color: bar.shaded(bar.tokens.startMid, startButton.shade)
                        }
                        GradientStop {
                            position: 1
                            color: bar.shaded(bar.tokens.startBottom, startButton.shade)
                        }
                    }
                }

                Row {
                    id: startContent

                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: startArea.pressed ? 1 : 0
                    x: 10
                    spacing: 5

                    Grid {
                        anchors.verticalCenter: parent.verticalCenter
                        columns: 2
                        spacing: 1
                        transform: Matrix4x4 {
                            matrix: Qt.matrix4x4(1, -0.15, 0, 2, 0.1, 1, 0, -1, 0, 0, 1, 0, 0, 0, 0, 1)
                        }

                        // Logo colours of the flag mark, intentionally independent of the theme palette.
                        Repeater {
                            model: ["#f25022", "#7fba00", "#00a4ef", "#ffb900"]

                            Rectangle {
                                id: pane

                                required property color modelData

                                width: 7
                                height: 7
                                radius: 1.5
                                antialiasing: true
                                color: pane.modelData
                            }
                        }
                    }

                    Item {
                        anchors.verticalCenter: parent.verticalCenter
                        implicitWidth: startLabel.implicitWidth + 1
                        implicitHeight: startLabel.implicitHeight + 1

                        Text {
                            x: 1
                            y: 1
                            text: startLabel.text
                            font: startLabel.font
                            color: Qt.rgba(0, 0, 0, 0.45)
                        }

                        Text {
                            id: startLabel

                            text: "start"
                            color: bar.tokens.text
                            font.family: Theme.fontSans
                            font.pixelSize: Theme.fontSize + 3
                            font.bold: true
                            font.italic: true
                        }
                    }
                }

                MouseArea {
                    id: startArea

                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: bar.startRequested()
                }
            }

            Item {
                id: taskArea

                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.leftMargin: 8
                Layout.rightMargin: 8

                Row {
                    id: taskRow

                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3

                    Repeater {
                        id: tasks

                        model: ScriptModel {
                            values: Windows.windows.filter(toplevel => toplevel.monitor?.name === bar.screen.name)
                        }

                        Rectangle {
                            id: task

                            required property HyprlandToplevel modelData
                            readonly property bool active: task.modelData.activated
                            readonly property bool minimized: Windows.minimized(task.modelData)

                            width: Math.min(160, Math.floor((taskArea.width - (tasks.count - 1) * taskRow.spacing) / tasks.count))
                            height: bar.height - 6
                            radius: 3
                            antialiasing: true
                            color: task.active ? bar.tokens.taskActive : bar.shaded(bar.tokens.taskInactive, taskMouse.containsMouse ? 1.12 : 1)
                            border.width: 1
                            border.color: Qt.darker(task.active ? bar.tokens.taskActive : bar.tokens.taskInactive, 1.35)

                            Rectangle {
                                visible: !task.active
                                x: 2
                                y: 1
                                width: parent.width - 4
                                height: 1
                                color: Qt.lighter(bar.tokens.taskInactive, 1.3)
                            }

                            // Inset shading that makes the focused window's button look pressed in.
                            Rectangle {
                                visible: task.active
                                x: 1
                                y: 1
                                width: parent.width - 2
                                height: 2
                                color: Qt.darker(bar.tokens.taskActive, 1.25)
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 6
                                anchors.rightMargin: 6
                                anchors.topMargin: task.active ? 1 : 0
                                spacing: 5

                                IconImage {
                                    implicitSize: 16
                                    source: Windows.icon(task.modelData)
                                    opacity: task.minimized ? 0.5 : 1
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: task.modelData.title
                                    elide: Text.ElideRight
                                    color: bar.tokens.text
                                    font.family: Theme.fontSans
                                    font.pixelSize: Theme.fontSize
                                }
                            }

                            MouseArea {
                                id: taskMouse

                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                                onClicked: mouse => {
                                    if (mouse.button === Qt.MiddleButton) {
                                        task.modelData.wayland?.close();
                                    } else {
                                        Windows.click(task.modelData);
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: trayRow.implicitWidth + 22
                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: bar.tokens.trayTop
                    }
                    GradientStop {
                        position: 1
                        color: bar.tokens.trayBottom
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Qt.lighter(bar.tokens.trayTop, 1.3)
                }

                Rectangle {
                    width: 1
                    height: parent.height
                    color: bar.tokens.trayBorder
                }

                Rectangle {
                    x: 1
                    width: 1
                    height: parent.height
                    color: Qt.lighter(bar.tokens.trayTop, 1.3)
                }

                Row {
                    id: trayRow

                    anchors.verticalCenter: parent.verticalCenter
                    x: 12
                    spacing: 6

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

                            anchors.verticalCenter: parent.verticalCenter
                            width: 16
                            height: 16

                            IconImage {
                                anchors.fill: parent
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

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        leftPadding: 4
                        text: Qt.formatDateTime(clock.date, "h:mm AP")
                        color: bar.tokens.text
                        font.family: Theme.fontSans
                        font.pixelSize: Theme.fontSize
                    }
                }
            }
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
