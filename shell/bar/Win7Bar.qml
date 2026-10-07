import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import Quickshell.Widgets
import "../theme"
import "../activate"
import "../tray"
import "../notifications"
import "../windows"

PanelWindow {
    id: bar

    signal startRequested

    readonly property var tokens: Theme.barTokens.win7
    // Tokens arrive as JSON strings; typed properties convert them for Qt.alpha and Gradient stops.
    readonly property color tint: bar.tokens.tint
    readonly property color highlight: bar.tokens.highlight
    readonly property color orbTop: bar.tokens.orbTop
    readonly property color orbBottom: bar.tokens.orbBottom
    readonly property color buttonHover: bar.tokens.buttonHover
    readonly property color buttonActive: bar.tokens.buttonActive
    readonly property color textColor: bar.tokens.text

    WlrLayershell.namespace: "temple-bar"
    BackgroundEffect.blurRegion: Region {
        item: Theme.blur ? bar.contentItem : null
    }

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

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: parent.height / 2
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: bar.highlight
                }
                GradientStop {
                    position: 1
                    color: Qt.alpha(bar.highlight, 0)
                }
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 1
            color: bar.highlight
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: showDesktop.width
        spacing: 4

        Item {
            id: start

            readonly property real orbSize: bar.height - 4

            Layout.preferredWidth: start.orbSize + 8
            Layout.fillHeight: true

            Rectangle {
                anchors.centerIn: parent
                width: start.orbSize + 4
                height: width
                radius: width / 2
                color: Qt.alpha(Theme.accent, 0.45)
                opacity: startMouse.containsMouse ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                    }
                }
            }

            Rectangle {
                id: orb

                anchors.centerIn: parent
                width: start.orbSize
                height: width
                radius: width / 2
                border.width: 1
                border.color: Qt.alpha(Qt.lighter(bar.orbTop, 1.5), 0.8)
                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: startMouse.containsMouse ? Qt.lighter(bar.orbTop, 1.15) : bar.orbTop
                    }
                    GradientStop {
                        position: 1
                        color: bar.orbBottom
                    }
                }

                Grid {
                    anchors.centerIn: parent
                    columns: 2
                    spacing: 1

                    Repeater {
                        model: ["#f25022", "#7fba00", "#00a4ef", "#ffb900"]

                        Rectangle {
                            required property string modelData

                            width: Math.round(orb.width * 0.2)
                            height: width
                            radius: 1.5
                            color: modelData
                        }
                    }
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 2
                    width: parent.width * 0.78
                    height: parent.height * 0.48
                    radius: height / 2
                    gradient: Gradient {
                        GradientStop {
                            position: 0
                            color: Qt.alpha(bar.textColor, 0.55)
                        }
                        GradientStop {
                            position: 1
                            color: Qt.alpha(bar.textColor, 0.05)
                        }
                    }
                }
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
            spacing: 2

            Repeater {
                model: ScriptModel {
                    values: Windows.windows.filter(window => window.screen?.name === bar.screen.name)
                }

                Rectangle {
                    id: task

                    required property QtObject modelData

                    readonly property color fill: task.modelData.activated ? bar.buttonActive : bar.buttonHover

                    width: 54
                    height: bar.height - 4
                    radius: 3
                    border.width: 1
                    border.color: task.modelData.activated ? bar.buttonActive : bar.highlight
                    gradient: Gradient {
                        GradientStop {
                            position: 0
                            color: task.fill
                        }
                        GradientStop {
                            position: 1
                            color: Qt.alpha(task.fill, task.fill.a / 3)
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 1
                        radius: 2
                        visible: task.modelData.activated
                        gradient: Gradient {
                            GradientStop {
                                position: 0.5
                                color: Qt.alpha(Theme.accent, 0)
                            }
                            GradientStop {
                                position: 1
                                color: Qt.alpha(Theme.accent, 0.45)
                            }
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: task.radius
                        color: bar.buttonHover
                        visible: taskMouse.containsMouse
                    }

                    IconImage {
                        anchors.centerIn: parent
                        implicitSize: 26
                        source: Windows.icon(task.modelData)
                        opacity: task.modelData.minimized ? 0.5 : 1
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 1
                        width: parent.width - 10
                        height: 2
                        radius: 1
                        color: Theme.accent
                        visible: task.modelData.activated
                    }

                    MouseArea {
                        id: taskMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                        onClicked: mouse => {
                            if (mouse.button === Qt.MiddleButton)
                                Windows.close(task.modelData);
                            else
                                Windows.click(task.modelData);
                        }
                    }
                }
            }
        }

        Row {
            Layout.alignment: Qt.AlignVCenter
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

                    width: 16
                    height: 16

                    IconImage {
                        anchors.fill: parent
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

        Column {
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 6
            Layout.rightMargin: 8

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(clock.date, "HH:mm")
                color: bar.textColor
                font.family: Theme.fontSans
                font.pixelSize: Theme.fontSize
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(clock.date, "d-M-yyyy")
                color: bar.textColor
                font.family: Theme.fontSans
                font.pixelSize: Theme.fontSize
            }
        }
    }

    Rectangle {
        id: showDesktop

        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 12
        color: showDesktopMouse.containsMouse ? bar.buttonActive : bar.buttonHover

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 1
            color: bar.highlight
        }

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
