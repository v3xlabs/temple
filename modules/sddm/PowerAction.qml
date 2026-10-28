import QtQuick
import QtQuick.Controls

// One icon button of the "Turn off computer" dialog.
AbstractButton {
    id: action
    property real u: 1
    property url art
    property string caption
    property int mnemonic: 0

    function px(n) {
        return Math.round(n * u);
    }

    implicitWidth: px(70)
    implicitHeight: px(32) + px(8) + px(16)
    hoverEnabled: true
    activeFocusOnTab: true
    padding: 0
    contentItem: Item {}
    background: Item {}
    Keys.onReturnPressed: click()
    Keys.onEnterPressed: click()
    Accessible.role: Accessible.Button
    Accessible.name: caption

    Image {
        id: picture
        x: Math.round((action.width - width) / 2)
        width: action.px(32)
        height: action.px(32)
        sourceSize: Qt.size(width, height)
        source: action.art
        Rectangle {
            anchors.fill: parent
            radius: action.px(5)
            color: "white"
            opacity: action.down ? 0 : action.hovered ? 0.22 : 0
        }
        Rectangle {
            anchors.fill: parent
            radius: action.px(5)
            color: "black"
            opacity: action.down ? 0.2 : 0
        }
    }
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: picture.height + action.px(5)
        width: text.implicitWidth + action.px(8)
        height: action.px(18)
        color: "transparent"
        border.width: action.visualFocus ? 1 : 0
        border.color: "#ffffff"
        radius: 2
        Text {
            id: text
            anchors.centerIn: parent
            textFormat: Text.StyledText
            text: action.mnemonic < 0 ? action.caption : action.caption.slice(0, action.mnemonic) + "<u>" + action.caption.charAt(action.mnemonic) + "</u>" + action.caption.slice(action.mnemonic + 1)
            color: "white"
            font.bold: true
            font.family: action.font.family
            font.pixelSize: action.px(11)
            style: Text.Raised
            styleColor: "#66001a66"
        }
    }
}
