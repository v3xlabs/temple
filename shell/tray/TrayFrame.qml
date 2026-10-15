import QtQuick
import "../frame"

// The backdrop of a flyout: the theme's frame in the `tray.popup` tokens, with
// the Aero sheen across the top and, under Windows 7, the white sheet inside.
Item {
    property alias title: frame.title

    Frame {
        id: frame

        anchors.fill: parent
        color: TrayStyle.popup.color
        border: TrayStyle.popup.border
        radius: TrayStyle.popup.radius
        sheet: TrayStyle.popup.sheet
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
