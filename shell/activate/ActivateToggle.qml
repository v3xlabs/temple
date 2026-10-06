import QtQuick
import Quickshell
import Quickshell.Widgets
import "../config"

// Bar icon that toggles the watermark. Absent unless the module enables the gag.
MouseArea {
    id: root

    property int size: 16

    visible: Config.activateLinux
    implicitWidth: visible ? size : 0
    implicitHeight: size
    hoverEnabled: true
    onClicked: ActivateLinux.toggle()

    IconImage {
        anchors.fill: parent
        source: Quickshell.iconPath("preferences-desktop-display", "computer")
        opacity: ActivateLinux.shown || root.containsMouse ? 1 : 0.6
    }
}
