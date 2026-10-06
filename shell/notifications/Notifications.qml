import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Wayland
import "../theme"

PanelWindow {
    id: root

    readonly property int defaultTimeout: 6000

    visible: server.trackedNotifications.values.length > 0
    WlrLayershell.namespace: "temple-notifications"
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Normal

    anchors {
        top: true
        right: true
    }
    margins {
        top: 8
        right: 8
    }
    implicitWidth: 380
    implicitHeight: column.implicitHeight
    color: "transparent"

    NotificationServer {
        id: server

        keepOnReload: true
        actionsSupported: true
        imageSupported: true
        onNotification: notification => notification.tracked = true
    }

    ColumnLayout {
        id: column

        width: parent.width
        spacing: 8

        Repeater {
            model: server.trackedNotifications

            Rectangle {
                id: card

                required property Notification modelData
                readonly property var defaultAction: modelData.actions.find(action => action.identifier === "default") ?? null

                Layout.fillWidth: true
                implicitHeight: content.implicitHeight + 24
                radius: Theme.radius
                color: Qt.alpha(Theme.surface, Theme.panelOpacity)
                border.color: card.modelData.urgency === NotificationUrgency.Critical ? Theme.accent : Theme.border
                border.width: 1

                Timer {
                    running: card.modelData.urgency !== NotificationUrgency.Critical && card.modelData.expireTimeout !== 0
                    interval: card.modelData.expireTimeout > 0 ? card.modelData.expireTimeout : root.defaultTimeout
                    onTriggered: card.modelData.expire()
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: mouse => {
                        if (mouse.button === Qt.LeftButton && card.defaultAction)
                            card.defaultAction.invoke();
                        else
                            card.modelData.dismiss();
                    }
                }

                RowLayout {
                    id: content

                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    Image {
                        readonly property string icon: card.modelData.image || card.modelData.appIcon

                        visible: icon !== ""
                        source: icon.startsWith("/") ? "file://" + icon : icon.includes("://") ? icon : Quickshell.iconPath(icon, true)
                        sourceSize.width: 40
                        sourceSize.height: 40
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        Layout.alignment: Qt.AlignTop
                        fillMode: Image.PreserveAspectFit
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Text {
                            Layout.fillWidth: true
                            text: card.modelData.appName
                            visible: text !== ""
                            color: Theme.textMuted
                            elide: Text.ElideRight
                            font.family: Theme.fontSans
                            font.pixelSize: Theme.fontSize - 2
                        }

                        Text {
                            Layout.fillWidth: true
                            text: card.modelData.summary
                            color: Theme.text
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                            font.family: Theme.fontSans
                            font.pixelSize: Theme.fontSize + 1
                            font.weight: Font.DemiBold
                        }

                        Text {
                            Layout.fillWidth: true
                            text: card.modelData.body
                            visible: text !== ""
                            textFormat: Text.PlainText
                            color: Theme.text
                            wrapMode: Text.Wrap
                            maximumLineCount: 5
                            elide: Text.ElideRight
                            font.family: Theme.fontSans
                            font.pixelSize: Theme.fontSize
                        }

                        Flow {
                            Layout.fillWidth: true
                            visible: actions.count > 0
                            spacing: 6

                            Repeater {
                                id: actions

                                model: card.modelData.actions.filter(action => action.identifier !== "default")

                                Rectangle {
                                    id: button

                                    required property NotificationAction modelData

                                    width: label.implicitWidth + 20
                                    height: 26
                                    radius: Theme.radius - 6
                                    color: hover.containsMouse ? Theme.selection : "transparent"
                                    border.color: Theme.border
                                    border.width: 1

                                    Text {
                                        id: label

                                        anchors.centerIn: parent
                                        text: button.modelData.text
                                        color: Theme.text
                                        font.family: Theme.fontSans
                                        font.pixelSize: Theme.fontSize - 1
                                    }

                                    MouseArea {
                                        id: hover

                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: button.modelData.invoke()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
