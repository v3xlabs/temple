pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "../tray"

// Bar icon that shows only while Health has a warning. Its tooltip names the
// warnings; a click lists them, and each opens the tool that deals with it.
Item {
    id: root

    property int size: 16

    readonly property var warnings: Health.warnings

    function open(warning: var) {
        popup.visible = false;
        Quickshell.execDetached(warning.kind === "cpu" ? ["plasma-systemmonitor"] : ["dolphin", warning.target]);
    }

    visible: root.warnings.length > 0
    implicitWidth: TrayStyle.barLabels ? barLabel.implicitWidth : root.size
    implicitHeight: root.size

    TrayIcon {
        visible: !TrayStyle.barLabels
        anchors.fill: parent
        implicitSize: root.size
        name: "dialog-warning"
    }

    Text {
        id: barLabel

        visible: TrayStyle.barLabels
        anchors.verticalCenter: parent.verticalCenter
        text: root.warnings.some(warning => warning.kind === "cpu") ? "Sys:CPU!" : "Sys:Disk!"
        color: area.containsMouse || popup.visible ? TrayStyle.barHighlight : TrayStyle.barIconTint
        font.family: TrayStyle.font
        font.pixelSize: TrayStyle.fontSize
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        onClicked: popup.toggle()
    }

    TrayTooltip {
        trigger: root
        text: root.warnings.map(warning => warning.title).join("\n")
        hovered: area.containsMouse && !popup.visible
    }

    TrayPopup {
        id: popup

        trigger: root
        panelWidth: 320

        Repeater {
            model: root.warnings

            TrayRow {
                required property var modelData

                width: parent.width
                icon: modelData.kind === "cpu" ? "utilities-system-monitor" : "drive-harddisk"
                iconSize: 32
                iconTint: "transparent"
                bold: true
                label: modelData.title
                detail: modelData.kind === "cpu" ? "Open System Monitor" : `Open ${modelData.target} in Dolphin`
                onActivated: root.open(modelData)
            }
        }
    }
}
