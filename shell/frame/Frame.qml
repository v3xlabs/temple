import QtQuick
import "../theme"
import "../macos"

// The backdrop of a flyout, tip or panel in the theme's frame: a plain
// rectangle from `color`, `border` and `radius`, the macOS glass material, or
// a TempleOS text-mode border that also carries the title.
Item {
    id: frame

    property string kind: Theme.frame
    property color color
    property color border
    property real radius
    property string title
    property bool double: true
    readonly property bool titled: frame.kind === "text"

    Rectangle {
        visible: frame.kind === "plain"
        anchors.fill: parent
        radius: frame.radius
        color: frame.color
        border.width: 1
        border.color: frame.border
        antialiasing: true
    }

    Loader {
        anchors.fill: parent
        active: frame.kind === "glass"
        sourceComponent: Glass {
            radius: frame.radius
        }
    }

    Loader {
        anchors.fill: parent
        active: frame.titled
        sourceComponent: TempleosFrame {
            title: frame.title
            double: frame.double
        }
    }
}
