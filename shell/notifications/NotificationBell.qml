pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import Quickshell.Widgets
import "../frame"
import "../theme"

// Tray bell with the unread count. Clicking it opens the notification history.
Item {
    id: root

    property int size: 16

    readonly property var center: Theme.notifications.center
    readonly property color bellTint: root.center.bellTint

    // A click on the bell first clears the focus grab; that same click must not reopen the panel.
    property double dismissedAt: 0

    function toggle() {
        if (panel.visible)
            panel.visible = false;
        else if (Date.now() - root.dismissedAt > 300)
            panel.visible = true;
    }

    implicitWidth: Theme.tray.barLabels ? barLabel.implicitWidth : root.size
    implicitHeight: root.size

    Text {
        id: barLabel

        visible: Theme.tray.barLabels
        anchors.verticalCenter: parent.verticalCenter
        text: NotificationStore.doNotDisturb ? "Msg:Off" : `Msg:${NotificationStore.unread}`
        color: NotificationStore.unread > 0 || panel.visible ? Theme.tray.barHighlight : Theme.tray.barIconTint
        font.family: Theme.fontSans
        font.pixelSize: Theme.fontSize
    }

    IconImage {
        visible: !Theme.tray.barLabels
        anchors.fill: parent
        source: Quickshell.iconPath("preferences-desktop-notification-bell", true)
        opacity: NotificationStore.doNotDisturb ? 0.5 : 1
        layer.enabled: root.bellTint.a > 0
        layer.effect: MultiEffect {
            // Brightness lifts the dark line art to white first, so colorization lands on the exact tint.
            brightness: 1
            colorization: 1
            colorizationColor: root.bellTint
        }
    }

    Rectangle {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: -2
        width: Math.max(8, Math.round(root.size * 0.5))
        height: width
        radius: width / 2
        visible: NotificationStore.doNotDisturb && !Theme.tray.barLabels
        color: "#7a7a7a"
        border.width: 1
        border.color: "#ffffff"

        Rectangle {
            anchors.centerIn: parent
            width: parent.width - 4
            height: Math.max(1, Math.round(parent.height / 5))
            color: "#ffffff"
        }
    }

    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: -4
        anchors.topMargin: -4
        width: Math.max(height, count.implicitWidth + 4)
        height: Math.max(10, Math.round(root.size * 0.7))
        radius: height / 2
        visible: NotificationStore.unread > 0 && !Theme.tray.barLabels
        color: "#e81123"
        border.width: 1
        border.color: "#ffffff"

        Text {
            id: count

            anchors.centerIn: parent
            text: NotificationStore.unread > 9 ? "9+" : String(NotificationStore.unread)
            color: "#ffffff"
            font.family: Theme.fontSans
            font.pixelSize: parent.height - 3
            font.bold: true
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.toggle()
    }

    PopupWindow {
        id: panel

        property double now: Date.now()

        anchor.item: root
        anchor.rect.x: root.width
        anchor.rect.y: Theme.barEdge === "top" ? root.height + 6 : -6
        anchor.edges: Edges.Top | Edges.Left
        anchor.gravity: Theme.barEdge === "top" ? Edges.Bottom | Edges.Left : Edges.Top | Edges.Left
        implicitWidth: root.center.width
        implicitHeight: frame.implicitHeight
        color: "transparent"
        visible: false
        onVisibleChanged: {
            if (!panel.visible)
                return;
            panel.now = Date.now();
            NotificationStore.markRead();
            content.forceActiveFocus();
        }

        HyprlandFocusGrab {
            windows: [panel]
            active: panel.backingWindowVisible
            onCleared: {
                root.dismissedAt = Date.now();
                panel.visible = false;
            }
        }

        Connections {
            target: NotificationStore
            enabled: panel.visible

            function onHistoryChanged() {
                NotificationStore.markRead();
            }
        }

        Timer {
            interval: 30000
            repeat: true
            running: panel.visible
            onTriggered: panel.now = Date.now()
        }

        Frame {
            id: frame

            anchors.fill: parent
            implicitHeight: content.implicitHeight + 2 * root.center.inset
            title: "Notifications"
            color: root.center.color
            border: root.center.border
            radius: root.center.radius

            FocusScope {
                id: content

                anchors.fill: parent
                anchors.margins: root.center.inset
                implicitHeight: column.implicitHeight
                focus: true
                Keys.onEscapePressed: panel.visible = false

                ColumnLayout {
                    id: column

                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: 0

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: header.implicitHeight + 16
                        radius: root.center.radius - 1
                        color: root.center.header

                        // Squares off the bottom corners so only the frame's top corners stay round.
                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: parent.radius
                            color: parent.color
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.leftMargin: parent.radius
                            anchors.rightMargin: parent.radius
                            height: 1
                            color: root.center.headerLine
                        }

                        RowLayout {
                            id: header

                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 12

                            Text {
                                visible: !frame.titled
                                Layout.fillWidth: true
                                text: "Notifications"
                                color: root.center.headerText
                                elide: Text.ElideRight
                                font.family: Theme.fontSans
                                font.pixelSize: Theme.textSize(1)
                                font.bold: true
                            }

                            Item {
                                implicitWidth: dnd.implicitWidth
                                implicitHeight: dnd.implicitHeight

                                RowLayout {
                                    id: dnd

                                    spacing: 6

                                    Loader {
                                        // An empty slot would still take the row spacing.
                                        visible: item !== null
                                        sourceComponent: ({
                                                checkbox: checkbox,
                                                switch: toggleSwitch
                                            })[root.center.toggle] ?? null
                                    }

                                    Text {
                                        text: (root.center.toggle === "text" ? (NotificationStore.doNotDisturb ? "[X] " : "[ ] ") : "") + "Do not disturb"
                                        color: root.center.headerText
                                        font.family: Theme.fontSans
                                        font.pixelSize: Theme.textSize(-1)
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: NotificationStore.toggleDoNotDisturb()
                                }
                            }

                            Text {
                                text: "Clear all"
                                visible: NotificationStore.history.length > 0
                                color: root.center.link
                                font.family: Theme.fontSans
                                font.pixelSize: Theme.textSize(-1)
                                font.underline: clear.containsMouse

                                MouseArea {
                                    id: clear

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: NotificationStore.clear()
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: Theme.lineWidth
                        visible: root.center.headerRule
                        color: root.center.separator
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 72
                        visible: NotificationStore.history.length === 0
                        text: "No new notifications"
                        color: root.center.muted
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.family: Theme.fontSans
                        font.pixelSize: Theme.fontSize
                    }

                    ListView {
                        id: list

                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.min(list.contentHeight, 440)
                        visible: NotificationStore.history.length > 0
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        model: ScriptModel {
                            values: NotificationStore.history
                        }

                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
                        }

                        delegate: Rectangle {
                            id: entry

                            required property var modelData

                            readonly property var live: NotificationStore.live(entry.modelData.id)
                            readonly property var defaultAction: NotificationStore.defaultAction(entry.live)
                            readonly property var buttons: entry.live ? entry.live.actions.filter(action => action.identifier !== "default") : []
                            readonly property string icon: NotificationStore.iconSource(entry.live ? entry.live.image || entry.live.appIcon : entry.modelData.icon) || NotificationStore.fallbackIcon(entry.modelData.urgency)

                            function invoke(action: NotificationAction) {
                                panel.visible = false;
                                action.invoke();
                            }

                            width: list.width
                            implicitHeight: entryContent.implicitHeight + 17
                            color: entryMouse.containsMouse && entry.defaultAction ? root.center.hover : "transparent"

                            MouseArea {
                                id: entryMouse

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: entry.defaultAction ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: {
                                    if (entry.defaultAction)
                                        entry.invoke(entry.defaultAction);
                                }
                            }

                            RowLayout {
                                id: entryContent

                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 8
                                anchors.leftMargin: 12
                                spacing: 10

                                IconImage {
                                    implicitSize: 32
                                    source: entry.icon
                                    visible: entry.icon !== ""
                                    Layout.alignment: Qt.AlignTop
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        Text {
                                            Layout.fillWidth: true
                                            text: entry.live?.appName ?? entry.modelData.appName
                                            color: root.center.muted
                                            elide: Text.ElideRight
                                            font.family: Theme.fontSans
                                            font.pixelSize: Theme.textSize(-2)
                                        }

                                        Text {
                                            text: NotificationStore.ago(entry.modelData.time, panel.now)
                                            color: root.center.muted
                                            font.family: Theme.fontSans
                                            font.pixelSize: Theme.textSize(-2)
                                        }

                                        CloseButton {
                                            onActivated: NotificationStore.remove(entry.modelData)
                                        }
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: entry.live?.summary ?? entry.modelData.summary
                                        color: root.center.text
                                        wrapMode: Text.Wrap
                                        maximumLineCount: 2
                                        elide: Text.ElideRight
                                        font.family: Theme.fontSans
                                        font.pixelSize: Theme.fontSize
                                        font.bold: !Theme.fontBitmap
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: entry.live?.body ?? entry.modelData.body
                                        visible: text !== ""
                                        textFormat: Text.PlainText
                                        color: root.center.text
                                        wrapMode: Text.Wrap
                                        maximumLineCount: 4
                                        elide: Text.ElideRight
                                        font.family: Theme.fontSans
                                        font.pixelSize: Theme.textSize(-1)
                                    }

                                    Flow {
                                        Layout.fillWidth: true
                                        Layout.topMargin: 4
                                        visible: entry.buttons.length > 0
                                        spacing: 6

                                        Repeater {
                                            model: entry.buttons

                                            NotificationButton {
                                                required property NotificationAction modelData

                                                text: modelData.text
                                                onActivated: entry.invoke(modelData)
                                            }
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                height: Theme.lineWidth
                                color: root.center.separator
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        implicitHeight: Math.max(0, root.center.radius - 2)
                    }
                }
            }
        }
    }

    Component {
        id: checkbox

        Rectangle {
            implicitWidth: 13
            implicitHeight: 13
            color: root.center.checkbox.fill
            border.width: 1
            border.color: root.center.checkbox.border

            Text {
                anchors.centerIn: parent
                visible: NotificationStore.doNotDisturb
                text: "✓"
                color: root.center.checkbox.check
                font.pixelSize: 12
                font.bold: true
            }
        }
    }

    Component {
        id: toggleSwitch

        Rectangle {
            implicitWidth: 28
            implicitHeight: 16
            radius: 8
            color: NotificationStore.doNotDisturb ? Theme.accent : "transparent"
            border.width: 1
            border.color: NotificationStore.doNotDisturb ? Theme.accent : root.center.muted

            Rectangle {
                x: NotificationStore.doNotDisturb ? parent.width - width - 3 : 3
                anchors.verticalCenter: parent.verticalCenter
                width: 10
                height: 10
                radius: 5
                color: NotificationStore.doNotDisturb ? "#ffffff" : root.center.muted

                Behavior on x {
                    NumberAnimation {
                        duration: 120
                    }
                }
            }
        }
    }
}
