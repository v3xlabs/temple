import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import Quickshell.Widgets
import "../theme"
import "../activate"
import "../windows"

PanelWindow {
    id: bar

    signal startRequested

    WlrLayershell.namespace: "temple-bar"

    anchors {
        top: true
        left: true
        right: true
    }
    margins {
        top: 0
        left: 0
        right: 0
    }
    implicitHeight: 36
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        radius: 0
        color: Qt.alpha(Theme.surface, Theme.surfaceOpacity)
        border.color: Theme.border
        border.width: 0

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 12

            Image {
                source: "vista.png"
                sourceSize.width: 20
                sourceSize.height: 20
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                fillMode: Image.PreserveAspectFit
                smooth: true

                MouseArea {
                    anchors.fill: parent
                    onClicked: bar.startRequested()
                }
            }

            Text {
                text: "temple"
                color: Theme.accent
                font.family: Theme.fontSans
                font.pixelSize: Theme.fontSize
                font.weight: Font.DemiBold
            }

            Row {
                spacing: 6

                Repeater {
                    model: Hyprland.workspaces

                    Rectangle {
                        id: pill

                        required property HyprlandWorkspace modelData

                        visible: pill.modelData.monitor?.name === bar.screen.name
                        width: 22
                        height: 22
                        radius: 7
                        color: pill.modelData.active ? Theme.accent : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: pill.modelData.id
                            color: pill.modelData.active ? Theme.surface : Theme.textMuted
                            font.family: Theme.fontSans
                            font.pixelSize: Theme.fontSize - 1
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: pill.modelData.activate()
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }

            Text {
                text: Hyprland.activeToplevel?.title ?? ""
                color: Theme.textMuted
                elide: Text.ElideRight
                Layout.maximumWidth: bar.width / 3
                font.family: Theme.fontSans
                font.pixelSize: Theme.fontSize
            }

            Item {
                Layout.fillWidth: true
            }

            Row {
                spacing: 8

                // This bar has no task list, so minimized windows wait here.
                Repeater {
                    model: ScriptModel {
                        values: Windows.windows.filter(toplevel => toplevel.monitor?.name === bar.screen.name && Windows.minimized(toplevel))
                    }

                    IconImage {
                        id: minimizedWindow

                        required property HyprlandToplevel modelData

                        anchors.verticalCenter: parent.verticalCenter
                        implicitSize: 18
                        source: Windows.icon(minimizedWindow.modelData)
                        opacity: 0.7

                        MouseArea {
                            anchors.fill: parent
                            onClicked: Windows.click(minimizedWindow.modelData)
                        }
                    }
                }
                ActivateToggle {
                    anchors.verticalCenter: parent.verticalCenter
                    size: 18
                }

                Repeater {
                    model: SystemTray.items

                    Item {
                        id: trayItem

                        required property SystemTrayItem modelData

                        width: 18
                        height: 18

                        Image {
                            anchors.fill: parent
                            source: trayItem.modelData.icon
                            sourceSize.width: 18
                            sourceSize.height: 18
                            fillMode: Image.PreserveAspectFit
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
                                    const position = trayItem.mapToItem(null, 0, trayItem.height);
                                    item.display(bar, position.x, position.y);
                                }
                            }
                            onWheel: wheel => trayItem.modelData.scroll(wheel.angleDelta.y, false)
                        }
                    }
                }
            }

            Text {
                text: Qt.formatDateTime(clock.date, "ddd d MMM  HH:mm")
                color: Theme.text
                font.family: Theme.fontSans
                font.pixelSize: Theme.fontSize
            }
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
