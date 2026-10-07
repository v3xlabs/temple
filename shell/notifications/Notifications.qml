pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Wayland
import Quickshell.Widgets
import "../theme"
import "../macos"
import "../windows"

// Popups for new notifications, stacked at the bar's end of the screen in the theme's layout.
// Hiding a popup leaves the notification alive so the bell can still act on it.
PanelWindow {
    id: root

    readonly property int defaultTimeout: 6000
    readonly property var popup: Theme.notifications.popup

    // Notification ids with a popup, newest first.
    property var shown: []

    readonly property var notifications: root.shown.map(id => NotificationStore.live(id)).filter(notification => notification !== null)
    readonly property var popups: {
        const popups = root.notifications.slice(0, root.popup.count);
        // The newest popup sits nearest the bar.
        return Theme.barEdge === "bottom" ? popups.reverse() : popups;
    }

    function hide(notification: Notification, expired: bool) {
        root.shown = root.shown.filter(id => id !== notification.id && NotificationStore.live(id) !== null);
        if (expired && notification.transient)
            notification.expire();
    }

    visible: root.popups.length > 0
    screen: Windows.focusedScreen
    WlrLayershell.namespace: "temple-notifications"
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Normal

    anchors {
        top: Theme.barEdge === "top"
        bottom: Theme.barEdge === "bottom"
        right: true
    }
    margins {
        top: root.popup.margin
        bottom: root.popup.margin
        right: 8
    }
    implicitWidth: root.popup.width
    implicitHeight: column.implicitHeight
    color: "transparent"

    Connections {
        target: NotificationStore

        function onPopupRequested(notification: Notification) {
            root.shown = [notification.id, ...root.shown];
        }

        function onDoNotDisturbChanged() {
            if (!NotificationStore.doNotDisturb)
                return;
            for (const notification of root.notifications)
                root.hide(notification, true);
            root.shown = [];
        }
    }

    Column {
        id: column

        width: parent.width
        spacing: 8

        Repeater {
            model: ScriptModel {
                values: root.popups
            }

            Item {
                id: popup

                required property Notification modelData

                readonly property var defaultAction: NotificationStore.defaultAction(popup.modelData)
                readonly property var buttons: popup.modelData.actions.filter(action => action.identifier !== "default")
                readonly property bool critical: popup.modelData.urgency === NotificationUrgency.Critical
                readonly property string icon: NotificationStore.iconSource(popup.modelData.image || popup.modelData.appIcon) || NotificationStore.fallbackIcon(popup.modelData.urgency)

                function activate() {
                    const action = popup.defaultAction;
                    root.hide(popup.modelData, false);
                    action?.invoke();
                }

                function invoke(action: NotificationAction) {
                    root.hide(popup.modelData, false);
                    action.invoke();
                }

                function dismiss() {
                    root.hide(popup.modelData, false);
                }

                width: column.width
                implicitHeight: view.implicitHeight

                HoverHandler {
                    id: hover
                }

                Timer {
                    running: !popup.critical && popup.modelData.expireTimeout !== 0 && !hover.hovered
                    interval: popup.modelData.expireTimeout > 0 ? popup.modelData.expireTimeout : root.defaultTimeout
                    onTriggered: root.hide(popup.modelData, true)
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: popup.defaultAction ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: mouse => {
                        if (mouse.button === Qt.LeftButton)
                            popup.activate();
                        else
                            popup.dismiss();
                    }
                }

                Loader {
                    id: view

                    width: parent.width
                    sourceComponent: ({
                            balloon: balloon,
                            toast: toast,
                            banner: banner,
                            window: textWindow
                        })[root.popup.layout]
                }

                // A text window with the app name in its border.
                Component {
                    id: textWindow

                    TempleosFrame {
                        id: textFrame

                        implicitHeight: textContent.implicitHeight + 32
                        title: popup.modelData.appName
                        color: popup.critical ? root.popup.critical : root.popup.color
                        background: root.popup.background

                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 32
                            height: 16
                            text: "[X]"
                            color: closeMouse.containsMouse ? textFrame.background : textFrame.color
                            font.family: Theme.fontSans
                            font.pixelSize: Theme.fontSize

                            Rectangle {
                                z: -1
                                anchors.fill: parent
                                color: closeMouse.containsMouse ? textFrame.color : textFrame.background
                            }

                            MouseArea {
                                id: closeMouse

                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: popup.dismiss()
                            }
                        }

                        ColumnLayout {
                            id: textContent

                            x: 16
                            y: 16
                            width: textFrame.width - 32
                            spacing: 0

                            Text {
                                Layout.fillWidth: true
                                text: popup.modelData.summary
                                visible: text !== ""
                                color: textFrame.color
                                wrapMode: Text.Wrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                                font.family: Theme.fontSans
                                font.pixelSize: Theme.fontSize
                            }

                            Text {
                                Layout.fillWidth: true
                                text: popup.modelData.body
                                visible: text !== ""
                                textFormat: Text.PlainText
                                color: textFrame.color
                                wrapMode: Text.Wrap
                                maximumLineCount: 6
                                elide: Text.ElideRight
                                font.family: Theme.fontSans
                                font.pixelSize: Theme.fontSize
                            }

                            Flow {
                                Layout.fillWidth: true
                                Layout.topMargin: 8
                                visible: popup.buttons.length > 0
                                spacing: 16

                                Repeater {
                                    model: popup.buttons

                                    NotificationButton {
                                        required property NotificationAction modelData

                                        text: modelData.text
                                        onActivated: popup.invoke(modelData)
                                    }
                                }
                            }
                        }
                    }
                }

                Component {
                    id: banner

                    Glass {
                        readonly property int inset: Math.max(10, Math.round(root.popup.radius / 2))

                        implicitHeight: Math.max(bannerContent.implicitHeight, 38) + inset * 2
                        radius: root.popup.radius

                        RowLayout {
                            id: bannerContent

                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: parent.inset
                            spacing: 10

                            IconImage {
                                implicitSize: 38
                                source: popup.icon
                                visible: popup.icon !== ""
                                Layout.alignment: Qt.AlignVCenter
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                RowLayout {
                                    Layout.fillWidth: true

                                    Text {
                                        Layout.fillWidth: true
                                        text: popup.modelData.summary || popup.modelData.appName
                                        color: root.popup.text
                                        elide: Text.ElideRight
                                        font.family: Theme.fontSans
                                        font.pixelSize: Theme.fontSize
                                        font.weight: Font.DemiBold
                                    }

                                    Text {
                                        text: "now"
                                        color: root.popup.muted
                                        font.family: Theme.fontSans
                                        font.pixelSize: Theme.fontSize - 1
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: popup.modelData.body
                                    visible: text !== ""
                                    textFormat: Text.PlainText
                                    color: root.popup.text
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 4
                                    elide: Text.ElideRight
                                    font.family: Theme.fontSans
                                    font.pixelSize: Theme.fontSize
                                }

                                Flow {
                                    Layout.fillWidth: true
                                    Layout.topMargin: 4
                                    visible: popup.buttons.length > 0
                                    spacing: 6

                                    Repeater {
                                        model: popup.buttons

                                        NotificationButton {
                                            required property NotificationAction modelData

                                            text: modelData.text
                                            onActivated: popup.invoke(modelData)
                                        }
                                    }
                                }
                            }
                        }

                        // The dismiss button appears at the top left corner under the pointer.
                        CloseButton {
                            x: 4
                            y: 4
                            visible: hover.hovered
                            onActivated: popup.dismiss()
                        }
                    }
                }

                Component {
                    id: balloon

                    Item {
                        id: balloonShape

                        readonly property int tail: 18
                        readonly property real bodyHeight: balloonContent.implicitHeight + 20

                        implicitHeight: balloonShape.bodyHeight + balloonShape.tail

                        Shape {
                            anchors.fill: parent
                            preferredRendererType: Shape.CurveRenderer

                            ShapePath {
                                strokeColor: root.popup.stroke
                                strokeWidth: 1
                                fillColor: root.popup.fill
                                startX: 8.5
                                startY: 0.5

                                PathLine {
                                    x: balloonShape.width - 8.5
                                    y: 0.5
                                }
                                PathArc {
                                    x: balloonShape.width - 0.5
                                    y: 8.5
                                    radiusX: 8
                                    radiusY: 8
                                }
                                PathLine {
                                    x: balloonShape.width - 0.5
                                    y: balloonShape.bodyHeight - 8
                                }
                                PathArc {
                                    x: balloonShape.width - 8.5
                                    y: balloonShape.bodyHeight
                                    radiusX: 8
                                    radiusY: 8
                                }
                                // The tail points down at the tray.
                                PathLine {
                                    x: balloonShape.width - 30
                                    y: balloonShape.bodyHeight
                                }
                                PathLine {
                                    x: balloonShape.width - 22
                                    y: balloonShape.bodyHeight + balloonShape.tail - 0.5
                                }
                                PathLine {
                                    x: balloonShape.width - 54
                                    y: balloonShape.bodyHeight
                                }
                                PathLine {
                                    x: 8.5
                                    y: balloonShape.bodyHeight
                                }
                                PathArc {
                                    x: 0.5
                                    y: balloonShape.bodyHeight - 8
                                    radiusX: 8
                                    radiusY: 8
                                }
                                PathLine {
                                    x: 0.5
                                    y: 8.5
                                }
                                PathArc {
                                    x: 8.5
                                    y: 0.5
                                    radiusX: 8
                                    radiusY: 8
                                }
                            }
                        }

                        ColumnLayout {
                            id: balloonContent

                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 10
                            spacing: 6

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                IconImage {
                                    implicitSize: 16
                                    source: popup.icon
                                    visible: popup.icon !== ""
                                    Layout.alignment: Qt.AlignTop
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: popup.modelData.summary || popup.modelData.appName
                                    color: root.popup.text
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 2
                                    elide: Text.ElideRight
                                    font.family: Theme.fontSans
                                    font.pixelSize: Theme.fontSize - 1
                                    font.bold: true
                                }

                                CloseButton {
                                    Layout.alignment: Qt.AlignTop
                                    onActivated: popup.dismiss()
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: popup.modelData.body
                                visible: text !== ""
                                textFormat: Text.PlainText
                                color: root.popup.text
                                wrapMode: Text.Wrap
                                maximumLineCount: 6
                                elide: Text.ElideRight
                                font.family: Theme.fontSans
                                font.pixelSize: Theme.fontSize - 1
                            }

                            Flow {
                                Layout.fillWidth: true
                                visible: popup.buttons.length > 0
                                spacing: 6

                                Repeater {
                                    model: popup.buttons

                                    NotificationButton {
                                        required property NotificationAction modelData

                                        text: modelData.text
                                        onActivated: popup.invoke(modelData)
                                    }
                                }
                            }
                        }
                    }
                }

                Component {
                    id: toast

                    Rectangle {
                        implicitHeight: toastContent.implicitHeight + 24
                        radius: 4
                        color: root.popup.color
                        border.color: popup.critical ? Theme.accent : root.popup.border
                        border.width: 1

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 1
                            height: parent.height / 2
                            radius: 3
                            gradient: Gradient {
                                GradientStop {
                                    position: 0
                                    color: root.popup.sheen
                                }
                                GradientStop {
                                    position: 1
                                    color: "#00ffffff"
                                }
                            }
                        }

                        RowLayout {
                            id: toastContent

                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 12
                            spacing: 12

                            IconImage {
                                implicitSize: 40
                                source: popup.icon
                                visible: popup.icon !== ""
                                Layout.alignment: Qt.AlignTop
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 3

                                RowLayout {
                                    Layout.fillWidth: true

                                    Text {
                                        Layout.fillWidth: true
                                        text: popup.modelData.appName
                                        color: root.popup.appName
                                        elide: Text.ElideRight
                                        font.family: Theme.fontSans
                                        font.pixelSize: Theme.fontSize - 1
                                    }

                                    CloseButton {
                                        onActivated: popup.dismiss()
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: popup.modelData.summary
                                    color: root.popup.summary
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 2
                                    elide: Text.ElideRight
                                    font.family: Theme.fontSans
                                    font.pixelSize: Theme.fontSize + 1
                                    font.bold: true
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: popup.modelData.body
                                    visible: text !== ""
                                    textFormat: Text.PlainText
                                    color: root.popup.body
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 5
                                    elide: Text.ElideRight
                                    font.family: Theme.fontSans
                                    font.pixelSize: Theme.fontSize
                                }

                                Flow {
                                    Layout.fillWidth: true
                                    Layout.topMargin: 4
                                    visible: popup.buttons.length > 0
                                    spacing: 6

                                    Repeater {
                                        model: popup.buttons

                                        NotificationButton {
                                            required property NotificationAction modelData

                                            text: modelData.text
                                            onActivated: popup.invoke(modelData)
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
}
