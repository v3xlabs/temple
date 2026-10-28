import QtQuick
import QtQuick.Controls

// A small footer choice: a caption and the current value in white, no chrome.
// The list opens above it.
ComboBox {
    id: combo
    property real u: 1
    property string caption

    function px(n) {
        return Math.round(n * u);
    }

    hoverEnabled: true
    padding: 0
    leftPadding: 0
    rightPadding: 0
    font.pixelSize: px(12)
    implicitHeight: px(17)
    implicitWidth: label.implicitWidth + px(14)
    background: Item {
        Rectangle {
            anchors.fill: parent
            anchors.margins: -Math.max(1, combo.px(2))
            radius: combo.px(2)
            color: "transparent"
            border.width: combo.visualFocus ? 1 : 0
            border.color: "#ffdc8a"
        }
    }
    indicator: Image {
        x: combo.width - width
        y: Math.round((combo.height - height) / 2)
        width: combo.px(7)
        height: combo.px(4)
        sourceSize: Qt.size(width, height)
        source: "assets/caret.svg"
    }
    contentItem: Row {
        id: label
        spacing: combo.px(4)
        readonly property real implicitWidth: caption.implicitWidth + current.implicitWidth + spacing
        Text {
            id: caption
            text: combo.caption
            color: "#dbe6ff"
            font: combo.font
            height: combo.height
            verticalAlignment: Text.AlignVCenter
        }
        Text {
            id: current
            text: combo.displayText
            color: "white"
            font.family: combo.font.family
            font.pixelSize: combo.font.pixelSize
            height: combo.height
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            width: Math.min(implicitWidth, combo.px(180))
            font.underline: true
            font.bold: combo.hovered
        }
    }
    delegate: ItemDelegate {
        id: item
        required property int index
        width: ListView.view ? ListView.view.width : combo.width
        height: combo.px(20)
        padding: 0
        leftPadding: combo.px(8)
        highlighted: combo.highlightedIndex === index
        hoverEnabled: true
        contentItem: Text {
            text: combo.textAt(item.index)
            color: "white"
            font: combo.font
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            color: item.highlighted || item.hovered ? "#3a63cc" : "transparent"
        }
    }
    popup: Popup {
        y: -height - combo.px(4)
        x: combo.width - width
        width: Math.max(combo.width, combo.px(170))
        implicitHeight: Math.min(list.contentHeight, combo.px(220)) + 2
        padding: 1
        contentItem: ListView {
            id: list
            clip: true
            implicitHeight: contentHeight
            model: combo.popup.visible ? combo.delegateModel : null
            currentIndex: combo.highlightedIndex
        }
        background: Rectangle {
            color: "#0f36a8"
            border.width: 1
            border.color: "#91aeee"
        }
    }
}
