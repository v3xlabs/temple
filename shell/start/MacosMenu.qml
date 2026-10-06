pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import "../apps"
import "../macos"
import "../session"

// The Apple menu. It drops from the Apple logo and holds the system items:
// settings, recent apps and the session actions.
PanelWindow {
    id: root

    property bool open: false
    property bool recentOpen: false
    property Item recentRow: null

    signal launcherRequested
    signal themesRequested

    readonly property var items: [
        {
            label: "System Settings…",
            run: () => root.act(() => root.themesRequested())
        },
        {
            separator: true
        },
        {
            label: "Recent Items",
            submenu: true
        },
        {
            separator: true
        },
        {
            label: "Sleep",
            run: () => root.act(() => Session.suspend())
        },
        {
            label: "Restart…",
            run: () => root.confirm("reboot")
        },
        {
            label: "Shut Down…",
            run: () => root.confirm("shutdown")
        },
        {
            separator: true
        },
        {
            label: "Lock Screen",
            shortcut: "⌘L",
            run: () => root.act(() => Session.lock())
        },
        {
            label: `Log Out ${Session.user}…`,
            run: () => root.confirm("logout")
        }
    ]

    function toggle(target: ShellScreen) {
        if (open && screen === target) {
            close();
            return;
        }
        screen = target;
        recentOpen = false;
        open = true;
        keys.forceActiveFocus();
    }

    function close() {
        open = false;
        recentOpen = false;
    }

    function act(run) {
        close();
        run();
    }

    // Also used by the launcher's session commands.
    function confirmOn(target: ShellScreen, action: string) {
        close();
        dialog.show(target, action);
    }

    function confirm(action: string) {
        confirmOn(screen, action);
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
    // The overlay spans the menu bar too, so the menu is placed below it explicitly.
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
        onClicked: root.close()
    }

    Item {
        id: keys

        anchors.fill: parent
        Keys.onEscapePressed: {
            if (root.recentOpen)
                root.recentOpen = false;
            else
                root.close();
        }
    }

    Glass {
        id: menu

        readonly property int inset: Math.max(5, Math.round(Macos.menuRadius / 2.5))

        x: 8
        y: Macos.height + 1
        width: 236
        height: list.implicitHeight + menu.inset * 2
        radius: Macos.menuRadius
        shadow: true

        MouseArea {
            anchors.fill: parent
        }

        Column {
            id: list

            x: menu.inset
            y: menu.inset
            width: menu.width - menu.inset * 2

            Repeater {
                model: root.items

                MenuRow {
                    id: row

                    required property var modelData

                    width: list.width
                    separator: row.modelData.separator ?? false
                    label: row.modelData.label ?? ""
                    shortcut: row.modelData.shortcut ?? ""
                    submenu: row.modelData.submenu ?? false
                    highlighted: row.submenu && root.recentOpen
                    onHovered: root.recentOpen = row.submenu
                    onActivated: {
                        if (row.submenu)
                            root.recentOpen = true;
                        else
                            row.modelData.run();
                    }
                    Component.onCompleted: if (row.submenu)
                        root.recentRow = row
                }
            }
        }
    }

    Glass {
        id: recent

        readonly property int inset: menu.inset

        visible: root.recentOpen
        x: menu.x + menu.width - 3
        y: menu.y + menu.inset + (root.recentRow?.y ?? 0) - recent.inset
        width: 260
        height: recentList.implicitHeight + recent.inset * 2
        radius: Macos.menuRadius
        shadow: true

        MouseArea {
            anchors.fill: parent
        }

        Column {
            id: recentList

            x: recent.inset
            y: recent.inset
            width: recent.width - recent.inset * 2

            MenuRow {
                width: recentList.width
                label: "Applications"
                enabled: false
            }

            MenuRow {
                visible: Apps.recentApplications.length === 0
                width: recentList.width
                label: "No Recent Items"
                enabled: false
            }

            Repeater {
                model: Apps.recentApplications

                MenuRow {
                    required property DesktopEntry modelData

                    width: recentList.width
                    icon: modelData.icon
                    label: modelData.name
                    onActivated: root.act(() => Apps.launch(modelData))
                }
            }
        }
    }

    MacosSessionDialog {
        id: dialog
    }

    // A menu item: label, optional icon, shortcut or submenu arrow; the selection
    // colour follows the pointer.
    component MenuRow: Item {
        id: item

        property string label
        property string icon
        property string shortcut
        property bool separator: false
        property bool submenu: false
        property bool highlighted: false

        signal activated
        signal hovered

        readonly property bool selected: item.enabled && !item.separator && (area.containsMouse || item.highlighted)
        readonly property color textColor: !item.enabled ? Macos.panelMuted : item.selected ? Macos.selectionText : Macos.panelText

        height: item.separator ? 11 : 22

        Rectangle {
            visible: item.separator
            anchors.verticalCenter: parent.verticalCenter
            x: 9
            width: parent.width - 18
            height: 1
            color: Macos.separator
        }

        Rectangle {
            anchors.fill: parent
            visible: item.selected
            radius: Macos.selectionRadius
            color: Macos.selection
        }

        IconImage {
            id: rowIcon

            visible: item.icon !== ""
            x: 9
            anchors.verticalCenter: parent.verticalCenter
            implicitSize: 16
            source: item.icon === "" ? "" : Apps.iconSource(item.icon)
        }

        Text {
            visible: !item.separator
            anchors.left: parent.left
            anchors.leftMargin: item.icon === "" ? 9 : 9 + 16 + 6
            anchors.right: trailing.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: item.label
            elide: Text.ElideRight
            color: item.textColor
            font.family: Macos.font
            font.pixelSize: Macos.fontSize
        }

        Text {
            id: trailing

            visible: !item.separator
            anchors.right: parent.right
            anchors.rightMargin: 9
            anchors.verticalCenter: parent.verticalCenter
            text: item.submenu ? "›" : item.shortcut
            color: item.selected ? item.textColor : Macos.panelMuted
            font.family: Macos.font
            font.pixelSize: item.submenu ? Macos.fontSize + 5 : Macos.fontSize
        }

        MouseArea {
            id: area

            anchors.fill: parent
            enabled: item.enabled && !item.separator
            hoverEnabled: true
            onContainsMouseChanged: if (containsMouse)
                item.hovered()
            onClicked: item.activated()
        }
    }
}
