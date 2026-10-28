import QtQuick
import QtQuick.Controls
import QtQuick.Shapes

// The XP notification balloon: cream body, black outline, a tail pointing up
// at the field it talks about.
Item {
    id: balloon
    property real u: 1
    property string kind: "error"
    property string title
    property string text
    property real tipX: px(250)
    readonly property real tailHeight: px(12)
    readonly property real tailWidth: px(14)
    readonly property real pad: px(10)
    readonly property real radius: px(8)

    function px(n) {
        return Math.round(n * u);
    }

    implicitWidth: px(300)
    implicitHeight: tailHeight + pad + head.height + (body.visible ? px(6) + body.height : 0) + pad
    Accessible.role: Accessible.AlertMessage
    Accessible.name: title + ". " + text

    Shape {
        anchors.fill: parent
        layer.enabled: true
        layer.samples: 4
        ShapePath {
            fillColor: "#ffffe1"
            strokeColor: "black"
            strokeWidth: 1
            startX: balloon.radius + 0.5
            startY: balloon.tailHeight + 0.5
            PathLine {
                x: balloon.tipX - balloon.tailWidth
                y: balloon.tailHeight + 0.5
            }
            PathLine {
                x: balloon.tipX
                y: 0.5
            }
            PathLine {
                x: balloon.tipX
                y: balloon.tailHeight + 0.5
            }
            PathLine {
                x: balloon.width - balloon.radius - 0.5
                y: balloon.tailHeight + 0.5
            }
            PathArc {
                x: balloon.width - 0.5
                y: balloon.tailHeight + balloon.radius + 0.5
                radiusX: balloon.radius
                radiusY: balloon.radius
                direction: PathArc.Clockwise
            }
            PathLine {
                x: balloon.width - 0.5
                y: balloon.height - balloon.radius - 0.5
            }
            PathArc {
                x: balloon.width - balloon.radius - 0.5
                y: balloon.height - 0.5
                radiusX: balloon.radius
                radiusY: balloon.radius
                direction: PathArc.Clockwise
            }
            PathLine {
                x: balloon.radius + 0.5
                y: balloon.height - 0.5
            }
            PathArc {
                x: 0.5
                y: balloon.height - balloon.radius - 0.5
                radiusX: balloon.radius
                radiusY: balloon.radius
                direction: PathArc.Clockwise
            }
            PathLine {
                x: 0.5
                y: balloon.tailHeight + balloon.radius + 0.5
            }
            PathArc {
                x: balloon.radius + 0.5
                y: balloon.tailHeight + 0.5
                radiusX: balloon.radius
                radiusY: balloon.radius
                direction: PathArc.Clockwise
            }
        }
    }
    Item {
        id: head
        x: balloon.pad
        y: balloon.tailHeight + balloon.pad
        width: balloon.width - 2 * balloon.pad
        height: balloon.px(16)
        Image {
            id: icon
            width: balloon.px(16)
            height: balloon.px(16)
            sourceSize: Qt.size(width, height)
            source: balloon.kind.length > 0 ? "assets/" + balloon.kind + ".svg" : ""
        }
        Label {
            x: icon.width + balloon.px(8)
            width: parent.width - x
            height: parent.height
            text: balloon.title
            textFormat: Text.PlainText
            color: "black"
            font.bold: true
            font.pixelSize: balloon.px(11)
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
    }
    Label {
        id: body
        visible: balloon.text.length > 0
        x: balloon.pad
        y: head.y + head.height + balloon.px(6)
        width: balloon.width - 2 * balloon.pad
        text: balloon.text
        textFormat: Text.PlainText
        color: "black"
        font.pixelSize: balloon.px(11)
        wrapMode: Text.WordWrap
    }
}
