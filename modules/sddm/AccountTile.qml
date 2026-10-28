import QtQuick
import QtQuick.Controls

// One account on the sign-in list. Selected, it becomes the navy tile that
// fades into the field and hosts the credential fields in `slot`.
AbstractButton {
    id: tile
    property real u: 1
    property string title
    property string picture
    property bool other: false
    property bool selected: false
    property bool dimmed: false
    readonly property bool isAccountTile: true
    readonly property bool lit: selected || hovered || visualFocus
    property alias slot: slotItem

    function px(n) {
        return Math.round(n * u);
    }

    implicitHeight: Math.max(px(76), slotItem.y + slotItem.childrenRect.height + px(4))
    hoverEnabled: true
    activeFocusOnTab: true
    padding: 0
    opacity: dimmed ? 0.5 : 1
    z: selected ? 1 : 0
    Accessible.role: Accessible.RadioButton
    Accessible.name: title
    Accessible.checked: selected
    Accessible.onPressAction: click()
    // Enter inside the hosted fields bubbles up here; only a focused tile acts on it.
    Keys.onReturnPressed: event => {
        event.accepted = tile.activeFocus;
        if (tile.activeFocus)
            click();
    }
    Keys.onEnterPressed: event => {
        event.accepted = tile.activeFocus;
        if (tile.activeFocus)
            click();
    }
    Behavior on opacity {
        NumberAnimation {
            duration: 150
        }
    }
    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }
    contentItem: Item {}
    background: Item {
        Rectangle {
            anchors.fill: parent
            radius: tile.px(8)
            opacity: tile.selected ? 1 : 0
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop {
                    position: 0
                    color: "#1242a6"
                }
                GradientStop {
                    position: 0.2
                    color: "#1242a6"
                }
                GradientStop {
                    position: 1
                    color: "#5a7edc"
                }
            }
            Rectangle {
                x: tile.px(8)
                width: parent.width - x
                height: 1
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop {
                        position: 0
                        color: "#9bb1ea"
                    }
                    GradientStop {
                        position: 0.6
                        color: "#1242a6"
                    }
                    GradientStop {
                        position: 1
                        color: "#5a7edc"
                    }
                }
            }
        }
        Rectangle {
            anchors.fill: parent
            radius: tile.px(8)
            color: "transparent"
            border.width: tile.visualFocus ? Math.max(1, tile.px(2)) : 0
            border.color: "#ffdc8a"
        }
    }

    Rectangle {
        x: tile.px(13)
        y: tile.px(14)
        width: frame.width
        height: frame.height
        radius: frame.radius
        color: "black"
        opacity: 0.25
    }
    Rectangle {
        id: frame
        x: tile.px(11)
        y: tile.px(12)
        width: tile.px(52)
        height: tile.px(52)
        radius: tile.px(3)
        color: "#d6e4fa"
        border.width: Math.max(1, tile.px(2))
        border.color: tile.lit ? "#ffb500" : "#c4d4f5"
        Image {
            anchors.fill: parent
            anchors.margins: frame.border.width
            source: tile.other ? "assets/avatar-other.svg" : "assets/avatar-user.svg"
            sourceSize: Qt.size(width, height)
            visible: !photo.visible
        }
        Image {
            id: photo
            anchors.fill: parent
            anchors.margins: frame.border.width
            source: tile.picture
            sourceSize: Qt.size(width, height)
            fillMode: Image.PreserveAspectCrop
            visible: status === Image.Ready
        }
    }
    Label {
        x: tile.px(75)
        y: tile.px(9)
        width: tile.width - x - tile.px(14)
        text: tile.title
        textFormat: Text.PlainText
        color: "white"
        font.bold: true
        font.pixelSize: tile.px(16)
        elide: Text.ElideRight
        maximumLineCount: 1
        style: Text.Raised
        styleColor: "#66001a66"
    }
    Item {
        id: slotItem
        x: tile.px(75)
        y: tile.px(32)
        width: tile.width - x - tile.px(14)
        height: childrenRect.height
    }
}
