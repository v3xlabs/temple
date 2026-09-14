import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../theme"

PanelWindow {
    id: root

    property bool open: false
    property var keybinds: []

    function toggle() {
        open = !open;
        if (open)
            focusScope.forceActiveFocus();
    }

    visible: open
    WlrLayershell.namespace: "temple-keybinds"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"

    FileView {
        path: Quickshell.env("TEMPLE_KEYBINDS") || "/etc/temple/keybinds.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.keybinds = JSON.parse(text())
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.open = false
    }

    FocusScope {
        id: focusScope

        anchors.fill: parent
        Keys.onEscapePressed: root.open = false
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Slash || event.key === Qt.Key_Question)
                root.open = false;
        }
    }

    Rectangle {
        anchors.centerIn: parent
        width: Math.min(parent.width - 80, 3 * 380 + 2 * 12 + 40)
        height: Math.min(parent.height - 80, content.implicitHeight + 40)
        radius: Theme.radius
        color: Qt.alpha(Theme.surface, Theme.surfaceOpacity + 0.15)
        border.color: Theme.border
        border.width: 1
        clip: true

        MouseArea {
            anchors.fill: parent
        }

        Column {
            id: content

            anchors.fill: parent
            anchors.margins: 20
            spacing: 14

            Text {
                text: "Keybinds"
                color: Theme.text
                font.family: Theme.fontSans
                font.pixelSize: Theme.fontSize + 5
                font.weight: Font.DemiBold
            }

            Flow {
                width: parent.width
                spacing: 12

                Repeater {
                    model: root.keybinds

                    Row {
                        id: row

                        required property var modelData

                        width: 380
                        height: 26
                        spacing: 10

                        Rectangle {
                            width: 170
                            height: parent.height
                            radius: Theme.radius - 8
                            color: Theme.selection

                            Text {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                verticalAlignment: Text.AlignVCenter
                                text: row.modelData.key
                                color: Theme.accent
                                elide: Text.ElideRight
                                font.family: Theme.fontMono
                                font.pixelSize: Theme.fontSize - 1
                            }
                        }

                        Text {
                            width: 200
                            height: parent.height
                            verticalAlignment: Text.AlignVCenter
                            text: row.modelData.description
                            color: Theme.text
                            elide: Text.ElideRight
                            font.family: Theme.fontSans
                            font.pixelSize: Theme.fontSize
                        }
                    }
                }
            }
        }
    }
}
