import QtQuick
import "../frame"

// The backdrop of a flyout: the theme's frame in the `tray.popup` tokens, with
// the Aero sheen across the top.
Item {
    property alias title: frame.title

    Frame {
        id: frame

        anchors.fill: parent
        color: TrayStyle.popup.color
        border: TrayStyle.popup.border
        radius: TrayStyle.popup.radius
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 1
        height: 48
        radius: 5
        gradient: Gradient {
            GradientStop {
                position: 0
                color: TrayStyle.popup.sheen
            }
            GradientStop {
                position: 1
                color: Qt.alpha(TrayStyle.popup.sheen, 0)
            }
        }
    }
}
