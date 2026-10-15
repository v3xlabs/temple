pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../background"
import "../pickers"
import "../windows"

// Every highlighted theme is applied at once, so the whole desktop previews it.
// Enter keeps it, Escape returns to the theme that was active on open.
PanelWindow {
    id: root

    property bool open: false
    property string original: ""

    function toggle() {
        if (open)
            cancel();
        else
            show();
    }

    // The screen is taken once: the picker takes the keyboard, which changes
    // the focused screen, and a picker that followed it would move, hand the
    // keyboard back, and move again.
    function show() {
        screen = Windows.focusedScreen;
        original = Theme.name;
        open = true;
        carousel.open(Theme.name);
    }

    function cancel() {
        if (Theme.name !== original)
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

    Carousel {
        id: carousel

        anchors.fill: parent
        entries: Theme.names.map(name => ({
                    key: name,
                    label: Theme.themes[name].label
                }))
        hint: "←/→ or scroll to preview  ·  type to filter  ·  Enter keeps  ·  Esc restores " + (Theme.themes[root.original]?.label ?? "")
        delegate: mock
        onHighlighted: key => Theme.set(key)
        onAccepted: root.open = false
        onCancelled: root.cancel()
    }

    component MockWindow: Rectangle {
        id: frame

        required property var theme
        required property var colours
        property string title: ""
        readonly property var titlebar: theme.window.titlebar
        readonly property bool buttonsLeft: titlebar.align === "left"
        readonly property int corner: Math.round(theme.radius * 0.6)
        default property alias body: face.data

        radius: frame.corner
        gradient: Gradient {
            GradientStop {
                position: 0
                color: frame.colours[0]
            }
            GradientStop {
                position: 1
                color: frame.colours[frame.colours.length - 1]
            }
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: Math.max(frame.theme.window.border, 1)
            radius: Math.max(frame.corner - anchors.margins, 0)
            clip: true
            color: frame.titlebar.color

            Text {
                x: frame.buttonsLeft ? (parent.width - width) / 2 : 10
                height: 22
                verticalAlignment: Text.AlignVCenter
                text: frame.title
                color: frame.titlebar.text
                font.family: frame.theme.font.sans
                font.pixelSize: 11
                font.weight: Font.DemiBold
            }

            Row {
                anchors.right: frame.buttonsLeft ? undefined : parent.right
                anchors.rightMargin: 5
                x: frame.buttonsLeft ? 8 : 0
                y: 4
                spacing: frame.buttonsLeft ? 6 : 4

                Repeater {
                    model: frame.buttonsLeft ? [frame.titlebar.close, frame.titlebar.minimize, frame.titlebar.maximize] : [frame.titlebar.minimize, frame.titlebar.maximize, frame.titlebar.close]

                    Rectangle {
                        required property color modelData

                        width: frame.buttonsLeft ? 12 : 14
                        height: width
                        y: frame.buttonsLeft ? 1 : 0
                        radius: frame.buttonsLeft ? width / 2 : 3
                        color: modelData
                    }
                }
            }

            Item {
                id: face

                y: 22
                width: parent.width
                height: parent.height - 22
            }
        }
    }

    // The theme drawn as a small desktop: wallpaper, bar, a terminal and a window.
    Component {
        id: mock

        Rectangle {
            id: desk

            required property string key
            readonly property var theme: Theme.themes[key]
            readonly property var bar: theme.bar
            readonly property var terminal: theme.terminal
            readonly property int corner: Math.round(theme.radius * 0.6)

            // Drawn at 640x400 and scaled up, so the mock keeps its proportions on any screen.
            width: 640
            height: 400
            transformOrigin: Item.TopLeft
            scale: parent.width / 640
            color: theme.palette.base00

            Image {
                anchors.fill: parent
                source: BackgroundState.effective || (BackgroundState.backgrounds[0] ?? "")
                sourceSize.width: width
                sourceSize.height: height
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }

            MockWindow {
                x: 300
                y: 48
                width: 280
                height: 170
                colours: desk.theme.window.inactive
                theme: desk.theme
                title: "Files"

                Rectangle {
                    anchors.fill: parent
                    color: desk.theme.palette.base01

                    Column {
                        x: 14
                        y: 14
                        spacing: 9

                        Repeater {
                            model: 5

                            Row {
                                id: entry

                                required property int index

                                spacing: 8

                                Rectangle {
                                    width: 14
                                    height: 12
                                    radius: 2
                                    color: entry.index === 1 ? desk.theme.accent : desk.theme.palette.base03
                                }

                                Rectangle {
                                    y: 3
                                    width: [120, 90, 150, 70, 110][entry.index]
                                    height: 6
                                    radius: 3
                                    color: desk.theme.palette.base04
                                }
                            }
                        }
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: 12
                        width: 54
                        height: 20
                        radius: desk.corner / 2
                        color: desk.theme.accent
                    }
                }
            }

            MockWindow {
                x: 52
                y: 28
                width: 340
                height: 210
                colours: desk.theme.window.active
                theme: desk.theme
                title: "kitty"

                Rectangle {
                    anchors.fill: parent
                    color: desk.terminal.base00

                    Column {
                        x: 10
                        y: 8
                        spacing: 3

                        Repeater {
                            model: [[["~/temple", desk.terminal.base0D], [" ❯ ", desk.terminal.base0B], ["ls", desk.terminal.base05]], [["modules  ", desk.terminal.base0D], ["shell  ", desk.terminal.base0D], ["flake.nix", desk.terminal.base05]], [["~/temple", desk.terminal.base0D], [" ❯ ", desk.terminal.base0B], ["nix build", desk.terminal.base05]], [["warning: ", desk.terminal.base0A], ["dirty tree", desk.terminal.base05]], [["error: ", desk.terminal.base08], ["just kidding", desk.terminal.base05]], [["~/temple", desk.terminal.base0D], [" ❯ ", desk.terminal.base0E], ["▌", desk.terminal.base05]]]

                            Row {
                                id: line

                                required property var modelData

                                Repeater {
                                    model: line.modelData

                                    Text {
                                        required property var modelData

                                        text: modelData[0]
                                        color: modelData[1]
                                        font.family: desk.theme.font.mono
                                        font.pixelSize: 12
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // A sketch of the theme's bar, at its edge.
            Loader {
                width: parent.width
                y: desk.theme.edge === "top" ? 0 : parent.height - height
                sourceComponent: ({
                        xp: xpBar,
                        win7: win7Bar,
                        macos: macosBar,
                        templeos: templeosBar
                    })[desk.theme.style]
            }

            Component {
                id: xpBar

                BorderImage {
                    height: 30
                    source: "../bar/assets/xp-taskbar.png"
                    border.top: 15
                    border.bottom: 11
                    horizontalTileMode: BorderImage.Repeat
                    verticalTileMode: BorderImage.Repeat
                    smooth: false

                    Image {
                        source: "../bar/assets/xp-start-normal.png"
                        smooth: false
                    }

                    BorderImage {
                        x: 107
                        width: 130
                        height: parent.height
                        source: "../bar/assets/xp-task-active.png"
                        border.left: 17
                        border.right: 5
                        border.top: 15
                        border.bottom: 8
                        smooth: false
                    }

                    BorderImage {
                        anchors.right: parent.right
                        width: 86
                        height: parent.height
                        source: "../bar/assets/xp-tray.png"
                        border.left: 34
                        border.right: 10
                        border.top: 12
                        border.bottom: 12
                        smooth: false

                        Text {
                            x: 34
                            anchors.verticalCenter: parent.verticalCenter
                            text: "12:00"
                            color: "white"
                            font.family: desk.theme.font.sans
                            font.pixelSize: 11
                        }
                    }
                }
            }

            Component {
                id: win7Bar

                Rectangle {
                    height: 40
                    color: Qt.alpha(desk.bar.tint, desk.bar.opacity)

                    BorderImage {
                        anchors.fill: parent
                        source: "../bar/assets/win7-taskbar.png"
                        border.top: 2
                        smooth: false
                    }

                    Image {
                        x: 0
                        anchors.verticalCenter: parent.verticalCenter
                        source: "../bar/assets/win7-start-normal.png"
                        smooth: false
                    }

                    Row {
                        x: 58
                        spacing: 2

                        Repeater {
                            model: [4, 1, 1]

                            BorderImage {
                                required property int modelData

                                width: 60
                                height: 40
                                source: "../bar/assets/win7-task-" + modelData + ".png"
                                border.left: 3
                                border.right: 3
                                border.top: 3
                                border.bottom: 3
                                smooth: false
                            }
                        }
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 24
                        anchors.verticalCenter: parent.verticalCenter
                        text: "12:00"
                        color: desk.bar.text
                        font.family: desk.theme.font.sans
                        font.pixelSize: 12
                    }
                }
            }

            Component {
                id: macosBar

                Rectangle {
                    height: 14
                    color: Qt.alpha(desk.bar.tint, desk.bar.opacity)

                    Row {
                        // The carousel cuts the top left corner of each card along its skew.
                        x: 32
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10

                        Text {
                            text: "\uf8ff"
                            color: desk.bar.text
                            font.family: desk.theme.font.sans
                            font.pixelSize: 10
                        }

                        Text {
                            text: "kitty"
                            color: desk.bar.text
                            font.family: desk.theme.font.sans
                            font.pixelSize: 9
                            font.bold: true
                        }
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Tue 7 Oct 12:00"
                        color: desk.bar.text
                        font.family: desk.theme.font.sans
                        font.pixelSize: 9
                    }
                }
            }

            Component {
                id: templeosBar

                // The TempleOS status line at its native 640 px: one 8 px text row.
                Rectangle {
                    height: 8
                    color: desk.bar.color

                    Row {
                        Repeater {
                            model: [["MENU", desk.bar.highlight], [" Tue 10/07 12:00:00 Mem:00B2F1A000 CPU", desk.bar.text], [" 3", desk.bar.highlight], [" 7", desk.bar.text], [" 1", desk.bar.highlight], [" 9", desk.bar.text], [" kitty ", desk.bar.highlight]]

                            Text {
                                required property var modelData

                                height: 8
                                text: modelData[0]
                                color: modelData[1]
                                font.family: desk.theme.font.sans
                                font.pixelSize: 6
                            }
                        }
                    }
                }
            }
        }
    }
}
