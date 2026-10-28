import QtQuick
import QtQuick.Controls

// The classic Luna push button: white to cream, dark blue border, orange glow
// on hover and a blue glow on focus.
Button {
    id: button
    property real u: 1

    function px(n) {
        return Math.round(n * u);
    }

    implicitHeight: px(23)
    implicitWidth: Math.max(px(75), contentItem.implicitWidth + px(24))
    padding: px(4)
    hoverEnabled: true
    Keys.onReturnPressed: click()
    Keys.onEnterPressed: click()
    font.pixelSize: px(11)
    contentItem: Text {
        text: button.text
        font: button.font
        color: button.enabled ? "black" : "#a1a192"
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
    background: Rectangle {
        radius: button.px(3)
        border.width: Math.max(1, button.px(1))
        border.color: button.enabled ? "#003c74" : "#c9c7ba"
        gradient: Gradient {
            GradientStop {
                position: 0
                color: button.down ? "#cecdc0" : "#ffffff"
            }
            GradientStop {
                position: 0.85
                color: button.down ? "#e4e3d8" : "#ecebe5"
            }
            GradientStop {
                position: 1
                color: button.down ? "#f1efe2" : "#d6d0c5"
            }
        }
        Rectangle {
            anchors.fill: parent
            anchors.margins: Math.max(1, button.px(1))
            radius: Math.max(1, button.px(2))
            color: "transparent"
            border.width: button.visualFocus || button.hovered ? Math.max(1, button.px(2)) : 0
            border.color: button.visualFocus ? "#98b8ea" : "#f8b330"
        }
    }
}
