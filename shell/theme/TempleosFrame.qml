pragma ComponentBehavior: Bound
import QtQuick

// A TempleOS window border: one 16 px text cell on each side, holding the
// ═ ║ (focused) or ─ │ glyphs of the 8x8 font at scale 2, and the title on the
// top row. Lines sit where those glyphs put their pixels, so the double frame
// is not centred in its cell.
Item {
    id: frame

    property bool double: true
    property color color: "#0000aa"
    property color background: "#ffffff"
    property string title

    Rectangle {
        anchors.fill: parent
        color: frame.background
    }

    Repeater {
        model: frame.double ? [
            {
                left: 4,
                top: 4,
                right: 2,
                bottom: 6
            },
            {
                left: 10,
                top: 8,
                right: 8,
                bottom: 10
            }
        ] : [
            {
                left: 6,
                top: 6,
                right: 6,
                bottom: 8
            }
        ]

        Item {
            id: loop

            required property var modelData

            x: loop.modelData.left
            y: loop.modelData.top
            width: frame.width - loop.modelData.left - loop.modelData.right
            height: frame.height - loop.modelData.top - loop.modelData.bottom

            Rectangle {
                width: parent.width
                height: 2
                color: frame.color
            }

            Rectangle {
                y: parent.height - 2
                width: parent.width
                height: 2
                color: frame.color
            }

            Rectangle {
                width: 4
                height: parent.height
                color: frame.color
            }

            Rectangle {
                x: parent.width - 4
                width: 4
                height: parent.height
                color: frame.color
            }
        }
    }

    Text {
        visible: frame.title !== ""
        x: 32
        width: Math.min(implicitWidth, frame.width - 64)
        height: 16
        clip: true
        text: frame.title
        color: frame.color
        font.family: Theme.fontSans
        font.pixelSize: Theme.fontSize

        Rectangle {
            z: -1
            width: parent.width
            height: parent.height
            color: frame.background
        }
    }
}
