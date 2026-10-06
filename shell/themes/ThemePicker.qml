import QtQuick
import Quickshell
import Quickshell.Wayland
import "../theme"

// Every highlighted theme is applied at once, so the whole desktop previews it.
// Enter keeps it, Escape returns to the theme that was active on open.
PanelWindow {
    id: root

    property bool open: false
    property string original: ""
    property int selected: 0

    function toggle() {
        if (open)
            cancel();
        else
            show();
    }

    function show() {
        original = Theme.name;
        selected = Math.max(Theme.names.indexOf(Theme.name), 0);
        open = true;
        focusScope.forceActiveFocus();
    }

    function highlight(index) {
        selected = (index + Theme.names.length) % Theme.names.length;
        Theme.set(Theme.names[selected]);
    }

    function keep() {
        open = false;
    }

    function cancel() {
        Theme.set(original);
        open = false;
    }

    visible: open
    WlrLayershell.namespace: "temple-themes"
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
        onClicked: root.cancel()
    }

    FocusScope {
        id: focusScope

        anchors.fill: parent
        Keys.onEscapePressed: root.cancel()
        Keys.onReturnPressed: root.keep()
        Keys.onEnterPressed: root.keep()
        Keys.onLeftPressed: root.highlight(root.selected - 1)
        Keys.onUpPressed: root.highlight(root.selected - 1)
        Keys.onRightPressed: root.highlight(root.selected + 1)
        Keys.onDownPressed: root.highlight(root.selected + 1)
        Keys.onTabPressed: root.highlight(root.selected + 1)
    }

    Rectangle {
        anchors.centerIn: parent
        width: Math.min(parent.width - 80, Theme.names.length * (180 + cards.spacing) - cards.spacing + 40)
        height: column.implicitHeight + 40
        radius: Theme.radius
        color: Qt.alpha(Theme.surface, Theme.panelOpacity)
        border.color: Theme.border
        border.width: 1

        MouseArea {
            anchors.fill: parent
        }

        Column {
            id: column

            anchors.fill: parent
            anchors.margins: 20
            spacing: 14

            Text {
                text: "Theme"
                color: Theme.text
                font.family: Theme.fontSans
                font.pixelSize: Theme.fontSize + 5
                font.weight: Font.DemiBold
            }

            Flow {
                id: cards

                width: parent.width
                spacing: 12

                Repeater {
                    model: Theme.names

                    Rectangle {
                        id: card

                        required property string modelData
                        required property int index
                        readonly property var theme: Theme.themes[modelData]
                        readonly property bool current: index === root.selected

                        width: 180
                        height: 132
                        radius: Math.max(Theme.radius - 4, 0)
                        color: card.current ? Theme.selection : "transparent"
                        border.color: card.current ? Theme.accent : Theme.border
                        border.width: card.current ? 2 : 1

                        Rectangle {
                            id: preview

                            x: 10
                            y: 10
                            width: parent.width - 20
                            height: 84
                            radius: Math.max(card.theme.radius / 2, 0)
                            clip: true
                            color: card.theme.palette.base00
                            border.color: card.theme.glass.border
                            border.width: 1

                            Rectangle {
                                x: 12
                                y: 12
                                width: parent.width * 0.55
                                height: 40
                                radius: Math.max(card.theme.radius / 3, 0)
                                color: card.theme.terminal?.base00 ?? card.theme.palette.base00
                                border.color: card.theme.window.active[0]
                                border.width: Math.max(card.theme.window.border, 1)

                                Text {
                                    x: 6
                                    y: 4
                                    text: "$ omp"
                                    color: card.theme.terminal?.base05 ?? card.theme.palette.base05
                                    font.family: card.theme.font.mono
                                    font.pixelSize: 9
                                }
                            }

                            Rectangle {
                                id: miniBar

                                readonly property bool atTop: card.theme.style === "temple"

                                y: miniBar.atTop ? 0 : parent.height - height
                                width: parent.width
                                height: 12
                                color: card.theme.style === "xp" ? card.theme.bar.taskbarMid : card.theme.style === "win7" ? card.theme.bar.tint : card.theme.glass.tint

                                Rectangle {
                                    visible: card.theme.style === "xp"
                                    width: 28
                                    height: parent.height
                                    radius: 4
                                    color: card.theme.bar.startMid ?? "transparent"
                                }

                                Rectangle {
                                    visible: card.theme.style === "win7"
                                    x: 3
                                    width: parent.height
                                    height: parent.height
                                    radius: height / 2
                                    color: card.theme.bar.orbTop ?? "transparent"
                                }
                            }

                            Rectangle {
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                anchors.margins: 18
                                width: 10
                                height: 10
                                radius: 5
                                color: card.theme.accent
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: preview.y + preview.height + 8
                            text: card.theme.label
                            color: Theme.text
                            font.family: card.theme.font.sans
                            font.pixelSize: Theme.fontSize
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: if (!card.current)
                                root.highlight(card.index)
                            onClicked: {
                                root.highlight(card.index);
                                root.keep();
                            }
                        }
                    }
                }
            }

            Text {
                text: "Arrows preview  ·  Enter keeps  ·  Esc restores " + (Theme.themes[root.original]?.label ?? "")
                color: Theme.textMuted
                font.family: Theme.fontSans
                font.pixelSize: Theme.fontSize - 1
            }
        }
    }
}
