import QtQuick
import QtQuick.Effects

// A macOS material: translucent fill, a hairline edge, and a specular rim
// with light falling across the top for Liquid Glass.
Rectangle {
    id: glass

    property color tint: Macos.panel
    property real tintOpacity: Macos.panelOpacity
    // Menus and alerts float over windows and cast a soft shadow.
    property bool shadow: false

    color: Qt.alpha(glass.tint, glass.tintOpacity)
    border.width: 1
    border.color: Macos.edge
    antialiasing: true
    layer.enabled: glass.shadow
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: "#59000000"
        shadowBlur: 1
        shadowVerticalOffset: 6
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: Math.max(glass.radius - 1, 0)
        color: "transparent"
        border.width: 1
        border.color: Macos.specular
        opacity: Macos.sheen > 0 ? 0.7 : 0.35
        antialiasing: true
    }

    Rectangle {
        visible: Macos.sheen > 0
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 1
        height: Math.min(parent.height - 2, Math.max(glass.radius * 2, 24))
        radius: Math.max(glass.radius - 1, 0)
        opacity: Macos.sheen
        gradient: Gradient {
            GradientStop {
                position: 0
                color: Qt.alpha(Macos.specular, 0.55)
            }
            GradientStop {
                position: 1
                color: Qt.alpha(Macos.specular, 0)
            }
        }
    }
}
