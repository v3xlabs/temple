import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../theme"

PanelWindow {
    id: root

    property bool open: false
    property var commands: []

    signal themesRequested

    function toggle() {
        open = !open;
        if (open) {
            query.text = "";
            query.forceActiveFocus();
        }
    }

    readonly property var entries: [...commands.map(c => ({
                    label: c.label,
                    detail: "Command",
                    run: () => Quickshell.execDetached(c.exec)
                })),
        {
            label: "Change theme",
            detail: Theme.label,
            run: () => root.themesRequested()
        },
        {
            label: "Reload shell",
            detail: "Command",
            run: () => Quickshell.reload(true)
        },
        ...DesktopEntries.applications.values.filter(app => !app.noDisplay).sort((a, b) => a.name.localeCompare(b.name)).map(app => ({
                    label: app.name,
                    detail: app.genericName,
                    search: [app.genericName, ...app.keywords].join(" ").toLowerCase(),
                    run: () => app.execute()
                }))]
    readonly property string needle: query.text.toLowerCase()
    readonly property var matches: entries.filter(e => e.label.toLowerCase().includes(needle) || (e.search ?? "").includes(needle)).slice(0, 10)
    property int selected: 0

    function run(entry) {
        open = false;
        entry.run();
    }

    FileView {
        path: Quickshell.env("TEMPLE_COMMANDS") || "/etc/temple/commands.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.commands = JSON.parse(text())
    }

    visible: open
    WlrLayershell.namespace: "temple-palette"
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

    MouseArea {
        anchors.fill: parent
        onClicked: root.open = false
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height / 4
        width: 560
        height: column.implicitHeight + 24
        radius: Theme.radius
        color: Qt.alpha(Theme.surface, Theme.panelOpacity)
        border.color: Theme.border
        border.width: 1

        ColumnLayout {
            id: column
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            TextInput {
                id: query
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                verticalAlignment: TextInput.AlignVCenter
                leftPadding: 8
                color: Theme.text
                font.family: Theme.fontSans
                font.pixelSize: Theme.fontSize + 5
                onTextChanged: root.selected = 0

                Text {
                    anchors.fill: parent
                    leftPadding: 8
                    verticalAlignment: Text.AlignVCenter
                    visible: query.text === ""
                    text: "Search commands"
                    color: Theme.textMuted
                    font: query.font
                }

                Keys.onEscapePressed: root.open = false
                Keys.onDownPressed: root.selected = Math.min(root.selected + 1, root.matches.length - 1)
                Keys.onUpPressed: root.selected = Math.max(root.selected - 1, 0)
                Keys.onReturnPressed: if (root.matches.length > 0)
                    root.run(root.matches[root.selected])
            }

            Repeater {
                model: root.matches

                Rectangle {
                    id: row

                    required property var modelData
                    required property int index

                    Layout.fillWidth: true
                    Layout.preferredHeight: 34
                    radius: Math.max(Theme.radius - 6, 0)
                    color: row.index === root.selected ? Theme.selection : "transparent"

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        x: 10
                        text: row.modelData.label
                        color: Theme.text
                        font.family: Theme.fontSans
                        font.pixelSize: Theme.fontSize + 1
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        text: row.modelData.detail ?? ""
                        color: Theme.textMuted
                        font.family: Theme.fontSans
                        font.pixelSize: Theme.fontSize - 1
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: root.selected = row.index
                        onClicked: root.run(row.modelData)
                    }
                }
            }
        }
    }
}
