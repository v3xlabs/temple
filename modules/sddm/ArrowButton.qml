import QtQuick
import QtQuick.Controls

Button {
    id: button
    property real u: 1

    function px(n) {
        return Math.round(n * u);
    }

    implicitWidth: px(24)
    implicitHeight: px(24)
    padding: 0
    hoverEnabled: true
    Keys.onReturnPressed: click()
    Keys.onEnterPressed: click()
    contentItem: Image {
        source: "assets/arrow.svg"
        sourceSize: Qt.size(button.px(24), button.px(24))
        fillMode: Image.PreserveAspectFit
    }
    background: Rectangle {
        radius: button.px(3)
        border.width: button.visualFocus ? button.px(2) : Math.max(1, button.px(1))
        border.color: button.visualFocus ? "#ffb500" : "white"
        opacity: button.enabled ? 1 : 0.5
        gradient: Gradient {
            GradientStop {
                position: 0
                color: button.down ? "#2f8f2f" : button.hovered ? "#5cc05c" : "#45a845"
            }
            GradientStop {
                position: 0.5
                color: button.down ? "#238023" : button.hovered ? "#3fae3f" : "#339933"
            }
            GradientStop {
                position: 1
                color: button.down ? "#146014" : "#1b871b"
            }
        }
    }
}
