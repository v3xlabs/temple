pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import Quickshell.Widgets
import "../apps"

// A theme icon, recoloured when `tint` is opaque.
IconImage {
    id: icon

    property string name
    property color tint: "transparent"

    source: icon.name === "" ? "" : Apps.iconSource(icon.name)
    layer.enabled: icon.tint.a > 0
    layer.effect: MultiEffect {
        // Brightness lifts the dark line art to white first, so colorization lands on the exact tint.
        brightness: 1
        colorization: 1
        colorizationColor: icon.tint
    }
}
