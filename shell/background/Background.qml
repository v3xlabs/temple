import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root

    property var backgrounds: []
    readonly property string background: backgrounds.length > 0 ? backgrounds[Quickshell.screens.indexOf(screen) % backgrounds.length] : ""

    WlrLayershell.namespace: "background"
    WlrLayershell.layer: WlrLayer.Background
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"

    Image {
        anchors.fill: parent
        source: root.background
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }

    FileView {
        path: Quickshell.env("TEMPLE_BACKGROUNDS") || "/etc/temple/backgrounds.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.backgrounds = JSON.parse(text())
    }
}
