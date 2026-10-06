import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../theme"

// Holding a modifier for a moment lists what each next key does, like which-key.
PanelWindow {
    id: root

    property var keybinds: []
    property string modifier: ""
    property bool open: false

    // Runs of binds like `Super + 1..9 -> Workspace 1..9` collapse into one row.
    readonly property var hints: {
        const prefix = modifier + " + ";
        const rows = [];
        const runs = {};
        for (const bind of keybinds) {
            if (!bind.key.startsWith(prefix))
                continue;
            const rest = bind.key.slice(prefix.length);
            const digit = rest.match(/^(.*?)(\d)$/);
            if (digit && bind.description.endsWith(" " + digit[2])) {
                const label = bind.description.slice(0, -2);
                const id = digit[1] + "#" + label;
                if (runs[id]) {
                    runs[id].first = Math.min(runs[id].first, Number(digit[2]));
                    runs[id].last = Math.max(runs[id].last, Number(digit[2]));
                } else {
                    runs[id] = {
                        prefix: digit[1],
                        first: Number(digit[2]),
                        last: Number(digit[2]),
                        description: label
                    };
                    rows.push(runs[id]);
                }
                continue;
            }
            rows.push({
                key: rest,
                description: bind.description
            });
        }
        return rows.map(row => row.key !== undefined ? row : {
                key: row.prefix + (row.first === row.last ? row.first : `${row.first}–${row.last}`),
                description: row.description
            }).sort((a, b) => a.key.split("+").length - b.key.split("+").length || a.key.localeCompare(b.key));
    }

    function hold(next: string) {
        modifier = next;
        delay.restart();
    }

    function release() {
        delay.stop();
        open = false;
    }

    visible: open
    screen: Quickshell.screens.find(screen => screen.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    WlrLayershell.namespace: "temple-keyhint"
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Normal
    anchors.bottom: true
    margins.bottom: 16
    implicitWidth: card.width
    implicitHeight: card.height
    color: "transparent"
    // Click-through: the hint never takes the pointer from the window under it.
    mask: Region {}

    Timer {
        id: delay
        interval: 400
        onTriggered: root.open = root.hints.length > 0
    }

    // A compositor event while the modifier is held means a bind already ran.
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if ((root.open || delay.running) && !event.data.includes("temple-keyhint"))
                root.release();
        }
    }

    Rectangle {
        id: card

        width: grid.width + 32
        height: title.height + grid.height + 40
        radius: Theme.radius
        color: Qt.alpha(Theme.surface, Theme.panelOpacity)
        border.color: Theme.border
        border.width: 1

        Text {
            id: title

            x: 16
            y: 14
            text: root.modifier + " +"
            color: Theme.accent
            font.family: Theme.fontSans
            font.pixelSize: Theme.fontSize + 1
            font.weight: Font.DemiBold
        }

        Grid {
            id: grid

            x: 16
            y: title.y + title.height + 10
            flow: Grid.TopToBottom
            rows: Math.min(root.hints.length, 8)
            columnSpacing: 24
            rowSpacing: 6

            Repeater {
                model: root.hints

                Row {
                    id: hint

                    required property var modelData

                    spacing: 10

                    Rectangle {
                        width: Math.max(keyLabel.implicitWidth + 12, 28)
                        height: keyLabel.implicitHeight + 6
                        radius: Math.max(Theme.radius - 8, 2)
                        color: Theme.selection

                        Text {
                            id: keyLabel

                            anchors.centerIn: parent
                            text: hint.modelData.key
                            color: Theme.accent
                            font.family: Theme.fontMono
                            font.pixelSize: Theme.fontSize - 1
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 180
                        text: hint.modelData.description
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
