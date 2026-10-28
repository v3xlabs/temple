import QtQuick
import QtQuick.Controls

// Temple's mark above the end of a modest wordmark, set the way XP sets its
// flag over the word "Windows".
Item {
    id: lockup
    property real u: 1
    property real size: 1

    function px(n) {
        return Math.round(n * u * size);
    }

    implicitWidth: word.implicitWidth
    implicitHeight: mark.height + word.implicitHeight - px(10)
    Accessible.role: Accessible.StaticText
    Accessible.name: word.text
    Image {
        id: mark
        source: "logo.svg"
        width: lockup.px(70)
        height: lockup.px(70)
        sourceSize: Qt.size(width, height)
        fillMode: Image.PreserveAspectFit
        anchors.right: parent.right
        anchors.rightMargin: -lockup.px(8)
    }
    Label {
        id: word
        text: "Temple"
        color: "white"
        font.bold: true
        font.pixelSize: lockup.px(28)
        anchors.right: parent.right
        anchors.bottom: parent.bottom
    }
}
