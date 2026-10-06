import QtQuick
import "../theme"

// A notification action in the look of the active theme.
Rectangle {
    id: root

    required property string text

    signal activated

    readonly property var button: Theme.notifications.button

    implicitWidth: label.implicitWidth + 2 * root.button.padding
    implicitHeight: root.button.height
    radius: root.button.radius
    border.width: root.button.borderWidth
    border.color: root.button.border
    color: mouse.pressed ? root.button.pressed : mouse.containsMouse ? root.button.hover : root.button.color

    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: root.radius - 1
        color: "transparent"
        border.width: 1
        border.color: mouse.containsMouse ? root.button.glow : "transparent"
    }

    Text {
        id: label

        anchors.centerIn: parent
        text: root.text
        color: mouse.containsMouse ? root.button.textHover : root.button.text
        font.family: Theme.fontSans
        font.pixelSize: Theme.textSize(-1)
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
