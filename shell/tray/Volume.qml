pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "../theme"

// Volume of the default audio output: wheel changes it, middle click mutes, left click opens the flyout.
Item {
    id: root

    property int size: 16

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool available: root.sink !== null && root.sink.audio !== null
    readonly property real volume: root.available ? root.sink.audio.volume : 0
    readonly property bool muted: root.available && root.sink.audio.muted
    readonly property int percent: Math.round(root.volume * 100)
    readonly property string iconName: !root.available || root.muted || root.volume <= 0 ? "audio-volume-muted" : root.volume < 0.34 ? "audio-volume-low" : root.volume < 0.67 ? "audio-volume-medium" : "audio-volume-high"
    readonly property var sinks: Pipewire.nodes.values.filter(node => node.isSink && node.audio !== null && !node.isStream)
    readonly property string status: !root.available ? "No audio device" : root.muted ? "Volume: muted" : `Volume: ${root.percent}%`

    // Touchpads report fractions of a wheel notch; whole notches of 120 each move the volume one step.
    property int wheelRest: 0

    function deviceName(node: PwNode): string {
        return node.description || node.nickname || node.name;
    }

    function setVolume(value: real) {
        if (root.available)
            root.sink.audio.volume = Math.max(0, Math.min(1.5, Math.round(value * 100) / 100));
    }

    function toggleMute() {
        if (root.available)
            root.sink.audio.muted = !root.sink.audio.muted;
    }

    function scroll(delta: int) {
        root.wheelRest += delta;
        const steps = Math.trunc(root.wheelRest / 120);
        if (steps === 0)
            return;
        root.wheelRest -= steps * 120;
        root.setVolume(root.volume + steps * 0.05);
    }

    function openSettings(command: list<string>) {
        popup.visible = false;
        Quickshell.execDetached(command);
    }

    implicitWidth: TrayStyle.barLabels ? barLabel.implicitWidth : root.size
    implicitHeight: root.size

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    TrayIcon {
        visible: !TrayStyle.barLabels
        anchors.fill: parent
        implicitSize: root.size
        name: root.iconName
        tint: TrayStyle.barIconTint
    }

    Text {
        id: barLabel

        visible: TrayStyle.barLabels
        anchors.verticalCenter: parent.verticalCenter
        text: !root.available ? "Vol:--" : root.muted ? "Vol:Mute" : `Vol:${root.percent}%`
        color: area.containsMouse || popup.visible ? TrayStyle.barHighlight : TrayStyle.barIconTint
        font.family: TrayStyle.font
        font.pixelSize: TrayStyle.fontSize
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton)
                root.toggleMute();
            else
                popup.toggle();
        }
        onWheel: wheel => root.scroll(wheel.angleDelta.y)
    }

    TrayTooltip {
        trigger: root
        text: root.status
        hovered: area.containsMouse && !popup.visible
    }

    component Separator: Rectangle {
        height: Theme.lineWidth
        color: TrayStyle.separator
    }

    component Label: Text {
        color: TrayStyle.text
        font.family: TrayStyle.font
        font.pixelSize: TrayStyle.fontSize
    }

    // A vertical slider. Value runs 0..1; the slider stops at 100% even though the wheel can boost to 150%.
    component LevelSlider: Item {
        id: slider

        property real value: 0

        signal moved(real value)
        signal scrolled(int delta)

        readonly property int thumbLength: 11
        readonly property int thumbBreadth: 22
        readonly property real travel: slider.height - slider.thumbLength
        readonly property real thumbOffset: (1 - slider.value) * slider.travel

        function valueAt(y: real): real {
            return Math.max(0, Math.min(1, 1 - (y - slider.thumbLength / 2) / slider.travel));
        }

        implicitWidth: slider.thumbBreadth
        implicitHeight: 140

        Rectangle {
            id: groove

            x: (slider.width - width) / 2
            y: slider.thumbLength / 2
            width: 5
            height: slider.travel
            radius: 1
            color: TrayStyle.volume.slider.groove
            border.width: 1
            border.color: TrayStyle.volume.slider.grooveBorder

            Rectangle {
                y: slider.thumbOffset
                width: groove.width
                height: groove.height - slider.thumbOffset
                radius: groove.radius
                color: TrayStyle.volume.slider.fill
            }
        }

        Repeater {
            model: TrayStyle.volume.slider.ticks

            Rectangle {
                required property int index

                x: slider.width - 3
                y: slider.thumbLength / 2 + slider.travel * index / 10
                width: 3
                height: 1
                color: TrayStyle.volume.slider.tick
            }
        }

        Rectangle {
            id: thumb

            x: (slider.width - slider.thumbBreadth) / 2
            y: slider.thumbOffset
            width: slider.thumbBreadth
            height: slider.thumbLength
            radius: 2
            border.width: 1
            border.color: handle.containsMouse || handle.pressed ? TrayStyle.volume.slider.thumbBorderHover : TrayStyle.volume.slider.thumbBorder
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: TrayStyle.volume.slider.thumb[0]
                }
                GradientStop {
                    position: 1
                    color: TrayStyle.volume.slider.thumb[1]
                }
            }
        }

        MouseArea {
            id: handle

            anchors.fill: parent
            hoverEnabled: true
            onPressed: mouse => slider.moved(slider.valueAt(mouse.y))
            onPositionChanged: mouse => {
                if (pressed)
                    slider.moved(slider.valueAt(mouse.y));
            }
            onWheel: wheel => slider.scrolled(wheel.angleDelta.y)
        }
    }

    // The Control Center slider: a capsule track filled from the left, the speaker glyph riding inside it.
    component MacosSlider: Item {
        id: track

        property real value: 0

        signal moved(real value)
        signal scrolled(int delta)

        function valueAt(x: real): real {
            return Math.max(0, Math.min(1, (x - track.height / 2) / (track.width - track.height)));
        }

        implicitHeight: 24

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: TrayStyle.volume.track.color
        }

        Rectangle {
            width: track.height + (track.width - track.height) * track.value
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

        MouseArea {
            anchors.fill: parent
            onPressed: mouse => track.moved(track.valueAt(mouse.x))
            onPositionChanged: mouse => {
                if (pressed)
                    track.moved(track.valueAt(mouse.x));
            }
            onWheel: wheel => track.scrolled(wheel.angleDelta.y)
        }
    }

    // Windows XP: the tray volume window.
    Component {
        id: trackbar

        Column {
            spacing: 6

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Volume"
            }

            LevelSlider {
                anchors.horizontalCenter: parent.horizontalCenter
                value: Math.min(root.volume, 1)
                onMoved: value => root.setVolume(value)
                onScrolled: delta => root.scroll(delta)
            }

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: `${root.percent}%`
                color: TrayStyle.textMuted
            }

            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: muteBox.implicitWidth
                height: muteBox.implicitHeight

                Row {
                    id: muteBox

                    spacing: 5

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 13
                        height: 13
                        border.width: 1
                        border.color: TrayStyle.volume.checkbox.border
                        gradient: Gradient {
                            GradientStop {
                                position: 0
                                color: TrayStyle.volume.checkbox.fill[0]
                            }
                            GradientStop {
                                position: 1
                                color: TrayStyle.volume.checkbox.fill[1]
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: root.muted
                            text: "✓"
                            color: TrayStyle.volume.checkbox.check
                            font.bold: true
                            font.pixelSize: 11
                        }
                    }

                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Mute"
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleMute()
                }
            }
        }
    }

    // Windows 7: the speaker flyout.
    Component {
        id: speaker

        Column {
            spacing: 6

            Row {
                spacing: 8

                TrayIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    implicitSize: 32
                    name: "audio-volume-high"
                    tint: TrayStyle.iconTint
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter

                    Label {
                        width: 190
                        elide: Text.ElideRight
                        text: root.available ? root.deviceName(root.sink) : ""
                    }

                    Label {
                        text: "Speakers"
                        color: TrayStyle.textMuted
                        font.pixelSize: TrayStyle.fontSize - 1
                    }
                }
            }

            Item {
                width: parent.width
                height: levelSlider.implicitHeight

                LevelSlider {
                    id: levelSlider

                    anchors.horizontalCenter: parent.horizontalCenter
                    value: Math.min(root.volume, 1)
                    onMoved: value => root.setVolume(value)
                    onScrolled: delta => root.scroll(delta)
                }

                Label {
                    anchors.left: levelSlider.right
                    anchors.leftMargin: 10
                    y: levelSlider.thumbOffset + levelSlider.thumbLength / 2 - height / 2
                    text: `${root.percent}`
                }
            }

            TrayButton {
                anchors.horizontalCenter: parent.horizontalCenter
                implicitWidth: 36
                implicitHeight: 30
                icon: root.muted ? "audio-volume-muted" : "audio-volume-high"
                down: root.muted
                onClicked: root.toggleMute()
            }
        }
    }

    // macOS: the Sound module of Control Center.
    Component {
        id: controlCenter

        Column {
            spacing: 8

            Label {
                leftPadding: 2
                text: "Sound"
                font.bold: true
            }

            MacosSlider {
                width: parent.width
                value: Math.min(root.volume, 1)
                onMoved: value => root.setVolume(value)
                onScrolled: delta => root.scroll(delta)
            }
        }
    }

    // TempleOS: a text-mode gauge of ░ and █ cells; a click or drag sets the level.
    Component {
        id: gauge

        Column {
            spacing: 4

            Label {
                width: parent.width
                elide: Text.ElideRight
                text: root.available ? root.deviceName(root.sink) : ""
            }

            Row {
                Label {
                    text: "Vol "
                }

                Label {
                    id: cells

                    readonly property int count: 10
                    readonly property int filled: Math.round(Math.min(root.volume, 1) * cells.count)

                    // The cell under the pointer becomes the last filled one.
                    function levelAt(x: real): real {
                        return Math.max(0, Math.min(cells.count, Math.ceil(x / cells.width * cells.count))) / cells.count;
                    }

                    text: "█".repeat(cells.filled) + "░".repeat(cells.count - cells.filled)

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onPressed: mouse => root.setVolume(cells.levelAt(mouse.x))
                        onPositionChanged: mouse => {
                            if (pressed)
                                root.setVolume(cells.levelAt(mouse.x));
                        }
                        onWheel: wheel => root.scroll(wheel.angleDelta.y)
                    }
                }

                Label {
                    text: ` ${root.percent}%`
                }
            }

            Label {
                text: (root.muted ? "[X]" : "[ ]") + " Mute"

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleMute()
                }
            }
        }
    }

    TrayPopup {
        id: popup

        trigger: root
        panelWidth: TrayStyle.volume.width

        Label {
            visible: !root.available
            width: parent.width
            topPadding: 4
            bottomPadding: 4
            horizontalAlignment: Text.AlignHCenter
            text: "No audio device"
            color: TrayStyle.textMuted
        }

        Loader {
            visible: root.available
            width: parent.width
            sourceComponent: ({
                    trackbar: trackbar,
                    speaker: speaker,
                    controlCenter: controlCenter,
                    gauge: gauge
                })[TrayStyle.volume.layout]
        }

        Separator {
            visible: root.sinks.length > 0
            width: parent.width
        }

        Label {
            visible: root.sinks.length > 0
            leftPadding: 6
            text: TrayStyle.volume.output
            color: TrayStyle.volume.outputStrong ? TrayStyle.text : TrayStyle.textMuted
            font.bold: TrayStyle.volume.outputStrong
            font.pixelSize: Theme.textSize(-1)
        }

        Column {
            id: deviceList

            width: parent.width
            spacing: 1

            Repeater {
                model: root.sinks

                TrayRow {
                    required property PwNode modelData

                    width: deviceList.width
                    radio: true
                    checked: modelData === root.sink
                    label: root.deviceName(modelData)
                    onActivated: Pipewire.preferredDefaultAudioSink = modelData
                }
            }
        }

        Separator {
            width: parent.width
        }

        TrayRow {
            width: parent.width
            link: TrayStyle.volume.settingsLink
            icon: "preferences-desktop-sound"
            iconTint: "transparent"
            label: "Sound settings"
            onActivated: root.openSettings(["pavucontrol"])
        }

        // A footer strip holding the Mixer link closes the flyout.
        Loader {
            active: TrayStyle.volume.mixer !== null
            visible: active
            width: parent.width
            sourceComponent: Rectangle {
                height: 30
                radius: 3
                color: TrayStyle.volume.mixer.color
                border.width: 1
                border.color: TrayStyle.volume.mixer.border

                Label {
                    anchors.centerIn: parent
                    text: "Mixer"
                    color: TrayStyle.link
                    font.underline: mixerArea.containsMouse
                }

                MouseArea {
                    id: mixerArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.openSettings(["pavucontrol", "--tab=1"])
                }
            }
        }
    }
}
