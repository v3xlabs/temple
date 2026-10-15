pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import Quickshell.Widgets
import "../clock"
import "../activate"
import "../notifications"
import "../tray"
import "../windows"

// The captured Start label preserves XP's GDI text rasterization.
PanelWindow {
    id: bar

    signal startRequested

    property bool startOpen: false

    FontLoader {
        id: tahoma
        source: "assets/xp-tahoma.ttf"
    }

    WlrLayershell.namespace: "temple-bar"

    anchors {
        bottom: true
        left: true
        right: true
    }
    implicitHeight: 30
    color: "transparent"

    BorderImage {
        anchors.fill: parent
        source: "assets/xp-taskbar.png"
        border.top: 15
        border.bottom: 11
        horizontalTileMode: BorderImage.Repeat
        verticalTileMode: BorderImage.Repeat
        smooth: false

        RowLayout {
            anchors.fill: parent
            spacing: 0

            Image {
                Layout.alignment: Qt.AlignTop
                source: startArea.pressed || bar.startOpen ? "assets/xp-start-pressed.png" : startArea.containsMouse ? "assets/xp-start-hover.png" : "assets/xp-start-normal.png"
                smooth: false

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

                    height: parent.height
                    spacing: 3

                    Repeater {
                        id: tasks

                        model: ScriptModel {
                            values: Windows.windows.filter(window => window.screen?.name === bar.screen.name)
                        }

                        BorderImage {
                            id: task

                            required property QtObject modelData

                            width: Math.min(160, Math.floor((taskArea.width - (tasks.count - 1) * taskRow.spacing) / tasks.count))
                            height: parent.height
                            // Luna draws the pressed state with the same frame as the focused window.
                            source: taskMouse.pressed ? "assets/xp-task-active.png" : task.modelData.activated ? (taskMouse.containsMouse ? "assets/xp-task-active-hover.png" : "assets/xp-task-active.png") : taskMouse.containsMouse ? "assets/xp-task-hover.png" : "assets/xp-task-normal.png"
                            border.left: 17
                            border.right: 5
                            border.top: 15
                            border.bottom: 8
                            smooth: false

                            IconImage {
                                x: 8
                                y: 7
                                implicitSize: 16
                                source: Windows.icon(task.modelData)
                                opacity: task.modelData.minimized ? 0.5 : 1
                            }

                            Text {
                                x: 27
                                width: parent.width - x - 4
                                height: parent.height
                                verticalAlignment: Text.AlignVCenter
                                text: task.modelData.title
                                elide: Text.ElideRight
                                color: "white"
                                renderType: Text.NativeRendering
                                font.family: tahoma.name
                                font.pixelSize: 11
                                font.hintingPreference: Font.PreferFullHinting
                            }

                            MouseArea {
                                id: taskMouse

                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                                onClicked: mouse => {
                                    if (mouse.button === Qt.MiddleButton) {
                                        Windows.close(task.modelData);
                                    } else {
                                        Windows.click(task.modelData);
                                    }
                                }
                            }
                        }
                    }
                }
            }

            BorderImage {
                Layout.fillHeight: true
                Layout.preferredWidth: trayRow.implicitWidth + 19 + 7
                source: "assets/xp-tray.png"
                border.left: 34
                border.right: 10
                border.top: 12
                border.bottom: 12
                smooth: false

                Row {
                    id: trayRow

                    anchors.verticalCenter: parent.verticalCenter
                    x: 19
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

                            Component.onCompleted: TrayIcons.add(bar.screen, trayItem, trayItem.modelData)
                            Component.onDestruction: TrayIcons.remove(trayItem)

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
                        id: clockLabel

                        anchors.verticalCenter: parent.verticalCenter
                        leftPadding: 4
                        text: Qt.formatDateTime(clock.date, "h:mm AP")
                        color: "white"
                        renderType: Text.NativeRendering
                        font.family: tahoma.name
                        font.pixelSize: 11
                        font.hintingPreference: Font.PreferFullHinting

                        MouseArea {
                            id: clockMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: dateTime.show(bar.screen)
                        }

                        TrayTooltip {
                            trigger: clockLabel
                            text: clock.date.toLocaleDateString(Qt.locale(), Locale.LongFormat)
                            hovered: clockMouse.containsMouse
                        }
                    }
                }
            }
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    XpDateTime {
        id: dateTime
    }
}
