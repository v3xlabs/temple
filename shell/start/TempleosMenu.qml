pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../theme"
import "../apps"
import "../session"

// The TempleOS pull-down menu (Adam/Menu.HC DrawMenu): yellow text on blue,
// the entry under the mouse or the keyboard cursor drawn yellow with blue text.
PanelWindow {
    id: root

    property bool open: false
    property int current: 0

    signal launcherRequested
    signal themesRequested

    readonly property var tokens: Theme.barTokens.templeos
    readonly property color background: root.tokens.color
    readonly property color highlight: root.tokens.highlight

    readonly property var entries: {
        const commands = Apps.commands.map(command => ({
                    label: command.label,
                    run: () => Apps.run(command)
                }));
        const recent = Apps.recentApplications.slice(0, 8).map(app => ({
                    label: app.name,
                    run: () => Apps.launch(app)
                }));
        const separator = [
            {
                separator: true
            }
        ];
        return commands.concat(separator, recent, recent.length > 0 ? separator : [], [
            {
                label: "Programs...",
                run: () => root.launcherRequested()
            },
            {
                label: "Themes...",
                run: () => root.themesRequested()
            }
        ], separator, [
            {
                label: "Lock",
                run: () => Session.lock()
            },
            {
                label: "Log out",
                confirm: "logout"
            },
            {
                label: "Suspend",
                confirm: "suspend"
            },
            {
                label: "Reboot",
                confirm: "reboot"
            },
            {
                label: "Shut down",
                confirm: "shutdown"
            }
        ]);
    }
    readonly property int columns: Math.max(...root.entries.map(entry => entry.label?.length ?? 0)) + 2

    function toggle(target: ShellScreen) {
        if (open && screen === target) {
            close();
            return;
        }
        screen = target;
        current = -1;
        move(1);
        open = true;
        keys.forceActiveFocus();
    }

    function close() {
        open = false;
    }

    function activate(index: int) {
        const entry = root.entries[index];
        if (!entry || entry.separator)
            return;
        if (entry.confirm) {
            confirmOn(screen, entry.confirm);
            return;
        }
        close();
        entry.run();
    }

    function move(step: int) {
        let index = root.current;
        do {
            index = (index + step + root.entries.length) % root.entries.length;
        } while (root.entries[index].separator)
        root.current = index;
    }

    // Also used by the launcher's session commands.
    function confirmOn(target: ShellScreen, action: string) {
        close();
        dialog.show(target, action);
    }

    // The overlay covers one screen; a click on another screen or a window
    // focused from elsewhere shows up as a focus change instead.
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (root.open && (event.name === "focusedmon" || (event.name === "activewindowv2" && event.data !== "")))
                root.close();
        }
    }

    visible: open
    WlrLayershell.namespace: "temple-startmenu"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Normal

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"

    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    FontMetrics {
        id: metrics

        font.family: Theme.fontSans
        font.pixelSize: Theme.fontSize
    }

    Item {
        id: keys

        anchors.fill: parent
        Keys.onEscapePressed: root.close()
        Keys.onUpPressed: root.move(-1)
        Keys.onDownPressed: root.move(1)
        Keys.onTabPressed: root.move(1)
        Keys.onBacktabPressed: root.move(-1)
        Keys.onReturnPressed: root.activate(root.current)
        Keys.onEnterPressed: root.activate(root.current)
    }

    Rectangle {
        width: root.columns * metrics.averageCharacterWidth
        height: menu.implicitHeight
        color: root.background

        MouseArea {
            anchors.fill: parent
        }

        Column {
            id: menu

            width: parent.width

            Repeater {
                model: root.entries

                Item {
                    id: row

                    required property var modelData
                    required property int index

                    readonly property bool lit: row.index === root.current && !row.modelData.separator

                    width: menu.width
                    height: metrics.height

                    Rectangle {
                        anchors.fill: parent
                        visible: row.lit
                        color: root.highlight
                    }

                    // ─ from the 8x8 font: its pixels fill the fourth of eight rows.
                    Rectangle {
                        visible: row.modelData.separator ?? false
                        y: Math.round(row.height * 3 / 8)
                        width: parent.width
                        height: Math.round(row.height / 8)
                        color: root.highlight
                    }

                    Text {
                        visible: !(row.modelData.separator ?? false)
                        anchors.fill: parent
                        text: " " + (row.modelData.label ?? "")
                        verticalAlignment: Text.AlignVCenter
                        color: row.lit ? root.background : root.highlight
                        font.family: Theme.fontSans
                        font.pixelSize: Theme.fontSize
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !(row.modelData.separator ?? false)
                        hoverEnabled: true
                        onEntered: root.current = row.index
                        onClicked: root.activate(row.index)
                    }
                }
            }
        }
    }

    TempleosSessionDialog {
        id: dialog
    }
}
