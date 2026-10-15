pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import "../theme"
import "../tray"
import "../frame"
import "../windows"

// The pop-up for volume and brightness changes. Plasma draws it in plasmashell
// when called on org.kde.osdService; here the shell watches the levels itself.
PanelWindow {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    property string kind: "volume"
    property real level: 0
    property bool muted: false
    property bool shown: false

    readonly property int percent: Math.round(root.level * 100)
    readonly property string title: root.kind === "volume" ? "Volume" : "Brightness"
    readonly property string iconName: root.kind === "brightness" ? "video-display-brightness" : root.muted || root.level <= 0 ? "audio-volume-muted" : root.level < 0.34 ? "audio-volume-low" : root.level < 0.67 ? "audio-volume-medium" : "audio-volume-high"
    readonly property bool macos: Theme.style === "macos"

    // Brightness of a display waiting for that display's maximum.
    property int pendingBrightness: 0

    function show(kind: string, level: real, muted: bool) {
        if (!root.shown)
            root.screen = Windows.focusedScreen;
        root.kind = kind;
        root.level = level;
        root.muted = muted;
        root.shown = true;
        hideTimer.restart();
    }

    function showVolume() {
        root.show("volume", root.sink.audio.volume, root.sink.audio.muted);
    }

    visible: root.shown
    color: "transparent"
    WlrLayershell.namespace: "temple-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Normal
    mask: Region {}
    BackgroundEffect.blurRegion: Region {
        item: Theme.blur ? panel : null
        radius: TrayStyle.popup.radius
    }

    // macOS shows the level under the menu bar on the right, the others low in the middle.
    anchors {
        top: root.macos
        right: root.macos
        bottom: !root.macos
    }
    margins {
        top: 8
        right: 8
        bottom: Math.round((root.screen?.height ?? 0) / 8)
    }
    implicitWidth: panel.implicitWidth
    implicitHeight: panel.implicitHeight

    Timer {
        id: hideTimer

        interval: 1500
        onTriggered: root.shown = false
    }

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    // A node reports its first volume before it is ready; only later changes are shown.
    Connections {
        target: root.sink?.ready ? root.sink.audio : null

        function onVolumesChanged() {
            root.showVolume();
        }
        function onMutedChanged() {
            root.showVolume();
        }
    }

    // Powerdevil sends each change as a BrightnessChanged signal. Only the
    // brightness keys ask for an indicator; dimming and profiles do not.
    Process {
        running: true
        command: ["busctl", "--user", "--json=short", "monitor", "--match", "type='signal',interface='org.kde.ScreenBrightness',member='BrightnessChanged'"]
        stdout: SplitParser {
            onRead: line => {
                const message = JSON.parse(line);
                if (message.member !== "BrightnessChanged")
                    return;
                const [display, brightness, , context] = message.payload.data;
                if (context !== "brightness_key")
                    return;
                root.pendingBrightness = brightness;
                maxBrightness.command = ["busctl", "--user", "--json=short", "get-property", "org.kde.Solid.PowerManagement", `/org/kde/ScreenBrightness/${display}`, "org.kde.ScreenBrightness.Display", "MaxBrightness"];
                maxBrightness.running = true;
            }
        }
    }

    Process {
        id: maxBrightness

        stdout: StdioCollector {
            onStreamFinished: {
                const max = JSON.parse(text).data;
                if (max > 0)
                    root.show("brightness", root.pendingBrightness / max, false);
            }
        }
    }

    component Label: Text {
        color: TrayStyle.text
        font.family: TrayStyle.font
        font.pixelSize: TrayStyle.fontSize
    }

    // The tray volume slider laid on its side: groove, fill, ticks and thumb.
    component Trackbar: Item {
        id: trackbar

        property real value: 0

        readonly property int thumbLength: 11
        readonly property real travel: trackbar.width - trackbar.thumbLength
        readonly property var slider: TrayStyle.volume.slider

        implicitHeight: 22

        Rectangle {
            id: groove

            x: trackbar.thumbLength / 2
            y: (trackbar.height - height) / 2
            width: trackbar.travel
            height: 5
            radius: 1
            color: trackbar.slider.groove
            border.width: 1
            border.color: trackbar.slider.grooveBorder

            Rectangle {
                width: groove.width * trackbar.value
                height: groove.height
                radius: groove.radius
                color: trackbar.slider.fill
            }
        }

        Repeater {
            model: trackbar.slider.ticks

            Rectangle {
                required property int index

                x: trackbar.thumbLength / 2 + trackbar.travel * index / (trackbar.slider.ticks - 1)
                y: trackbar.height - 3
                width: 1
                height: 3
                color: trackbar.slider.tick
            }
        }

        Rectangle {
            x: trackbar.travel * trackbar.value
            width: trackbar.thumbLength
            height: trackbar.height
            radius: 2
            border.width: 1
            border.color: trackbar.slider.thumbBorder
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: trackbar.slider.thumb[0]
                }
                GradientStop {
                    position: 1
                    color: trackbar.slider.thumb[1]
                }
            }
        }
    }

    // Windows XP and 7: icon, title and the tray slider in a flyout frame.
    Component {
        id: trackbarBody

        Row {
            spacing: 10

            TrayIcon {
                anchors.verticalCenter: parent.verticalCenter
                implicitSize: 32
                name: root.iconName
                tint: TrayStyle.iconTint
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Label {
                    text: root.title
                }

                Row {
                    spacing: 8

                    Trackbar {
                        width: 160
                        value: Math.min(root.level, 1)
                    }

                    Label {
                        id: percentLabel

                        anchors.verticalCenter: parent.verticalCenter
                        width: widest.width
                        horizontalAlignment: Text.AlignRight
                        text: `${root.percent}%`

                        TextMetrics {
                            id: widest

                            font: percentLabel.font
                            text: "150%"
                        }
                    }
                }
            }
        }
    }

    // macOS: the Control Center module, its capsule track holding the glyph.
    Component {
        id: controlCenterBody

        Column {
            width: TrayStyle.volume.width - TrayStyle.popup.padding * 2
            spacing: 8

            Item {
                width: parent.width
                height: heading.implicitHeight

                Label {
                    id: heading

                    leftPadding: 2
                    text: root.kind === "volume" ? "Sound" : "Display"
                    font.bold: true
                }

                Label {
                    anchors.right: parent.right
                    rightPadding: 2
                    text: `${root.percent}%`
                    color: TrayStyle.textMuted
                }
            }

            Item {
                id: track

                width: parent.width
                height: 24

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: TrayStyle.volume.track.color
                }

                Rectangle {
                    width: track.height + (track.width - track.height) * Math.min(root.level, 1)
                    height: track.height
                    radius: height / 2
                    color: TrayStyle.volume.track.fill
                    border.width: 1
                    border.color: TrayStyle.volume.track.border
                }

                TrayIcon {
                    x: 5
                    anchors.verticalCenter: parent.verticalCenter
                    implicitSize: 14
                    name: root.iconName
                    tint: TrayStyle.textMuted
                }
            }
        }
    }

    // TempleOS: a text-mode gauge in a titled border, the label standing in for the icon.
    Component {
        id: gaugeBody

        Label {
            readonly property int cells: 16
            readonly property int filled: Math.round(Math.min(root.level, 1) * cells)

            text: (root.kind === "brightness" ? "Brt" : root.muted ? "Mute" : "Vol").padEnd(5) + "█".repeat(filled) + "░".repeat(cells - filled) + `${root.percent}%`.padStart(5)
        }
    }

    Item {
        id: panel

        readonly property int padding: TrayStyle.popup.padding

        anchors.fill: parent
        implicitWidth: body.implicitWidth + panel.padding * 2
        implicitHeight: body.implicitHeight + panel.padding * 2

        Frame {
            anchors.fill: parent
            color: TrayStyle.popup.color
            border: TrayStyle.popup.border
            radius: TrayStyle.popup.radius
            sheet: TrayStyle.popup.sheet
            title: root.title
        }

        // Aero sheen across the top of the glass.
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 1
            height: 48
            radius: 5
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: TrayStyle.popup.sheen
                }
                GradientStop {
                    position: 1
                    color: Qt.alpha(TrayStyle.popup.sheen, 0)
                }
            }
        }

        Loader {
            id: body

            // Loaded only while shown: a body of another style would read tokens the new theme lacks.
            active: root.shown
            x: panel.padding
            y: panel.padding
            sourceComponent: ({
                    xp: trackbarBody,
                    win7: trackbarBody,
                    macos: controlCenterBody,
                    templeos: gaugeBody
                })[Theme.style]
        }
    }
}
