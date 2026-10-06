import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import "../theme"
import "../windows"

// Alt+Tab: every window, most recently used first, with live previews.
// Releasing Alt (reported by the Hyprland config) switches to the highlighted
// window. Escape cancels; arrow keys and the mouse also pick a window.
PanelWindow {
    id: root

    property bool open: false
    property int selected: 0
    property var windows: []
    readonly property int cardWidth: 236
    readonly property int cardHeight: 186

    function step(delta: int) {
        if (open) {
            selected = (selected + delta + windows.length) % windows.length;
            return;
        }
        windows = Windows.byRecentUse();
        if (windows.length === 0)
            return;
        // The first Alt+Tab lands on the window used before the current one.
        selected = (Math.min(1, windows.length - 1) * delta + windows.length) % windows.length;
        open = true;
        focusScope.forceActiveFocus();
    }

    function commit() {
        if (!open)
            return;
        open = false;
        Windows.focus(windows[selected]);
    }

    visible: open
    screen: Quickshell.screens.find(screen => screen.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    WlrLayershell.namespace: "temple-switcher"
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

    FocusScope {
        id: focusScope

        anchors.fill: parent
        Keys.onEscapePressed: root.open = false
        Keys.onReturnPressed: root.commit()
        Keys.onLeftPressed: root.step(-1)
        Keys.onRightPressed: root.step(1)
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.open = false
    }

    Rectangle {
        anchors.centerIn: parent
        width: cards.width + 32
        height: cards.height + 32
        radius: Theme.radius
        color: Qt.alpha(Theme.surface, Theme.panelOpacity)
        border.color: Theme.border
        border.width: 1

        MouseArea {
            anchors.fill: parent
        }

        Flow {
            id: cards

            readonly property int perRow: Math.max(1, Math.floor((root.width - 112) / (root.cardWidth + spacing)))

            x: 16
            y: 16
            width: Math.min(root.windows.length, perRow) * (root.cardWidth + spacing) - spacing
            spacing: 12

            Repeater {
                model: root.windows

                Rectangle {
                    id: entry

                    required property HyprlandToplevel modelData
                    required property int index
                    readonly property bool current: entry.index === root.selected

                    width: root.cardWidth
                    height: root.cardHeight
                    radius: Math.max(Theme.radius - 4, 2)
                    color: entry.current ? Theme.selection : "transparent"
                    border.color: entry.current ? Theme.accent : "transparent"
                    border.width: 2

                    Item {
                        id: frame

                        x: 8
                        y: 8
                        width: parent.width - 16
                        height: 136

                        ScreencopyView {
                            id: preview

                            anchors.centerIn: parent
                            captureSource: entry.modelData.wayland
                            live: root.open
                            constraintSize: Qt.size(frame.width, frame.height)
                            visible: hasContent && !Windows.minimized(entry.modelData)
                        }

                        IconImage {
                            anchors.centerIn: parent
                            implicitSize: 64
                            visible: !preview.visible
                            source: Windows.icon(entry.modelData)
                        }
                    }

                    Row {
                        x: 10
                        y: frame.y + frame.height + 10
                        width: parent.width - 20
                        spacing: 8

                        IconImage {
                            id: icon

                            implicitSize: 20
                            source: Windows.icon(entry.modelData)
                        }

                        Text {
                            anchors.verticalCenter: icon.verticalCenter
                            width: parent.width - icon.width - 8
                            text: entry.modelData.title
                            elide: Text.ElideRight
                            color: Theme.text
                            font.family: Theme.fontSans
                            font.pixelSize: Theme.fontSize
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: root.selected = entry.index
                        onClicked: {
                            root.selected = entry.index;
                            root.commit();
                        }
                    }
                }
            }
        }
    }
}
