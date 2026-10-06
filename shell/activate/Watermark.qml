import QtQuick
import Quickshell
import Quickshell.Wayland
import "../theme"

PanelWindow {
    id: root

    visible: ActivateLinux.shown
    WlrLayershell.namespace: "temple-activate-linux"
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Normal
    anchors {
        bottom: true
        right: true
    }
    margins {
        bottom: 48
        right: 72
    }
    implicitWidth: text.width
    implicitHeight: text.height
    color: "transparent"
    mask: Region {}

    Column {
        id: text

        spacing: 2

        Text {
            text: "Activate Linux"
            color: Qt.rgba(0.82, 0.82, 0.82, 0.6)
            font.family: Theme.fontSans
            font.pixelSize: 24
        }

        Text {
            text: "Go to Settings to activate Linux."
            color: Qt.rgba(0.82, 0.82, 0.82, 0.6)
            font.family: Theme.fontSans
            font.pixelSize: 14
        }
    }
}
