import QtQuick

// A push button in the flyout style of the current theme.
Rectangle {
    id: button

    property string text
    property string icon
    property bool down: false
    readonly property bool active: area.containsMouse || button.down
    readonly property var stops: button.down ? TrayStyle.button.down : area.containsMouse ? TrayStyle.button.hover : TrayStyle.button.rest

    signal clicked

    implicitWidth: Math.max(content.implicitWidth + 16, 64)
    implicitHeight: Math.max(content.implicitHeight + 8, 23)
    radius: Math.min(height / 2, TrayStyle.button.radius)
    border.width: TrayStyle.button.borderWidth
    border.color: area.containsMouse ? TrayStyle.button.borderHover : TrayStyle.button.border
    gradient: Gradient {
        GradientStop {
            position: 0
            color: button.stops[0]
        }
        GradientStop {
            position: 1
            color: button.stops[1]
        }
    }

    Row {
        id: content

        anchors.centerIn: parent
        spacing: 4

        TrayIcon {
            visible: button.icon !== ""
            anchors.verticalCenter: parent.verticalCenter
            implicitSize: 16
            name: button.icon
            tint: button.active ? TrayStyle.button.activeIcon : TrayStyle.iconTint
        }

        Text {
            visible: button.text !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: button.text
            color: button.active ? TrayStyle.button.activeText : TrayStyle.text
            font.family: TrayStyle.font
            font.pixelSize: TrayStyle.fontSize
        }
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: button.clicked()
    }
}
