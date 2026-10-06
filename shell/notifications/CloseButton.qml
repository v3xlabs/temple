import QtQuick
import "../theme"

// The small × that dismisses a notification, in the look of the active theme.
Rectangle {
    id: root

    signal activated

    readonly property var close: Theme.notifications.close

    implicitWidth: root.close.size
    implicitHeight: implicitWidth
    radius: root.close.radius
    border.width: root.close.borderWidth
    border.color: mouse.containsMouse ? root.close.borderHover : root.close.border
    color: mouse.containsMouse ? root.close.hover : root.close.color

    Text {
        anchors.centerIn: parent
        text: "×"
        color: mouse.containsMouse ? root.close.glyphHover : root.close.glyph
        font.family: Theme.fontSans
        font.pixelSize: root.close.glyphSize
        font.bold: true
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        onClicked: root.activated()
    }
}
