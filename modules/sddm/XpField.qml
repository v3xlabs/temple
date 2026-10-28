import QtQuick
import QtQuick.Controls

TextField {
    id: field
    property real u: 1

    function px(n) {
        return Math.round(n * u);
    }

    implicitWidth: px(160)
    implicitHeight: px(24)
    topPadding: 0
    bottomPadding: 0
    leftPadding: px(6)
    rightPadding: px(6)
    font.pixelSize: px(13)
    color: "black"
    selectionColor: "#316ac5"
    selectedTextColor: "white"
    passwordCharacter: "\u2022"
    verticalAlignment: TextInput.AlignVCenter
    selectByMouse: true
    background: Rectangle {
        radius: field.px(3)
        color: field.enabled ? "white" : "#c9d6f3"
    }
}
