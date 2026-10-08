pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Wayland
import "../theme"
import "../windows"
import "../notifications"

// Clippy shows what Voxtype does: he listens while it records, works while it
// transcribes, and reads Voxtype's notifications out in his balloon.
// Animations play the way clippy.js plays them: a frame leads to the next one
// or to a weighted random branch, and once the animation is asked to end, to
// its exit branch.
PanelWindow {
    id: root

    readonly property string assets: "/etc/temple/clippy"

    // The content of Voxtype's state file: idle, recording, streaming or transcribing.
    property string voxtype: "idle"
    // False once the microphone has been quiet for a moment of the recording.
    property bool hearing: true
    property var agent: null
    property bool present: false
    property string playing: ""
    property int frameIndex: 0
    property bool exiting: false
    property var queue: []
    property Notification message: null

    readonly property bool recording: voxtype === "recording" || voxtype === "streaming"
    // What Clippy keeps doing once the queue is empty. Empty sends him away.
    readonly property string background: recording ? (hearing ? "Hearing_1" : "IdleFingerTap") : voxtype === "transcribing" ? "Processing" : message !== null ? "RestPose" : ""
    readonly property var image: agent && playing !== "" ? agent.animations[playing].frames[frameIndex].images?.[0] ?? null : null

    function play(name: string) {
        frameIndex = 0;
        playing = name;
        exiting = false;
        step.interval = agent.animations[name].frames[0].duration;
        step.restart();
    }

    function next() {
        const frames = agent.animations[playing].frames;
        const frame = frames[frameIndex];
        let index = frameIndex + 1;
        if (exiting && frame.exitBranch !== undefined) {
            index = frame.exitBranch;
        } else if (frame.branching) {
            let roll = Math.random() * 100;
            for (const branch of frame.branching.branches) {
                if (roll <= branch.weight) {
                    index = branch.frameIndex;
                    break;
                }
                roll -= branch.weight;
            }
        }
        if (index < frames.length) {
            frameIndex = index;
            step.interval = frames[index].duration;
            step.restart();
        } else {
            finished();
        }
    }

    function finished() {
        if (queue.length > 0) {
            const [first, ...rest] = queue;
            queue = rest;
            play(first);
        } else if (background !== "") {
            play(background);
        } else if (playing !== "Hide") {
            play("Hide");
        } else {
            playing = "";
            present = false;
        }
    }

    // Brings Clippy on screen, or ends what he is playing so the queue or the
    // new background comes next.
    function wake() {
        if (agent === null)
            return;
        if (present) {
            exiting = true;
            return;
        }
        screen = Windows.focusedScreen;
        present = true;
        play("Show");
    }

    function say(notification: Notification) {
        message = notification;
        balloonTimer.interval = notification.urgency === NotificationUrgency.Critical ? 8000 : 4000;
        balloonTimer.restart();
        const gesture = notification.urgency === NotificationUrgency.Critical ? "Alert" : "Explain";
        if (!queue.includes(gesture))
            queue = [...queue, gesture];
        wake();
    }

    onBackgroundChanged: {
        if (background !== "")
            wake();
        else
            exiting = true;
    }

    onRecordingChanged: {
        hearing = true;
        silence.stop();
    }

    Component.onCompleted: NotificationStore.assistant = true
    Component.onDestruction: NotificationStore.assistant = false

    visible: present
    color: "transparent"
    WlrLayershell.namespace: "temple-clippy"
    WlrLayershell.layer: WlrLayer.Top
    exclusionMode: ExclusionMode.Normal
    mask: Region {}

    anchors {
        bottom: true
        right: true
    }
    margins {
        bottom: 8
        right: 16
    }
    implicitWidth: Theme.notifications.popup.width
    implicitHeight: sprite.height + (balloon.visible ? balloon.height : 0)

    FileView {
        path: root.assets + "/agent.json"
        printErrors: false
        onLoaded: {
            root.agent = JSON.parse(text());
            if (root.background !== "")
                root.wake();
        }
    }

    // FileView notices a created file only when its directory exists, and the
    // shell can start before the Voxtype daemon makes it.
    Process {
        running: true
        command: ["mkdir", "-p", Quickshell.env("XDG_RUNTIME_DIR") + "/voxtype"]
        onExited: voxtypeState.path = command[2] + "/state"
    }

    FileView {
        id: voxtypeState

        watchChanges: true
        printErrors: false
        onLoaded: root.voxtype = text().trim() || "idle"
        onLoadFailed: root.voxtype = "idle"
        onFileChanged: reload()
    }

    Process {
        running: root.recording
        command: ["voxtype-audio-bridge"]
        stdout: SplitParser {
            onRead: line => {
                const frame = JSON.parse(line);
                if (frame.vad === undefined)
                    return;
                if (frame.vad === 1) {
                    root.hearing = true;
                    silence.restart();
                } else if (root.hearing && !silence.running) {
                    silence.start();
                }
            }
        }
    }

    Timer {
        id: silence

        interval: 2000
        onTriggered: root.hearing = false
    }

    Timer {
        id: step

        onTriggered: root.next()
    }

    Timer {
        id: balloonTimer

        onTriggered: {
            const shown = root.message;
            root.message = null;
            if (shown?.transient)
                shown.expire();
        }
    }

    Connections {
        target: NotificationStore

        function onAssistantRequested(notification: Notification) {
            root.say(notification);
        }
    }

    // Voxtype replaces its notification in place, which emits no new notification.
    Connections {
        target: root.message

        function onSummaryChanged() {
            root.say(root.message);
        }
        function onBodyChanged() {
            root.say(root.message);
        }
    }

    Item {
        id: sprite

        anchors.right: parent.right
        anchors.bottom: parent.bottom
        width: root.agent?.framesize[0] ?? 0
        height: root.agent?.framesize[1] ?? 0
        clip: true

        Image {
            x: -(root.image?.[0] ?? 0)
            y: -(root.image?.[1] ?? 0)
            visible: root.image !== null
            source: "file://" + root.assets + "/map.png"
            smooth: false
        }
    }

    Item {
        id: balloon

        readonly property var popup: Theme.notifications.popup
        readonly property int tail: 16
        readonly property real bodyHeight: content.implicitHeight + 20
        // The tail points at Clippy's head.
        readonly property real tip: width - sprite.width / 2

        visible: root.message !== null
        anchors.bottom: sprite.top
        width: parent.width
        height: bodyHeight + tail

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeColor: balloon.popup.stroke
                strokeWidth: 1
                fillColor: balloon.popup.fill
                startX: 8.5
                startY: 0.5

                PathLine {
                    x: balloon.width - 8.5
                    y: 0.5
                }
                PathArc {
                    x: balloon.width - 0.5
                    y: 8.5
                    radiusX: 8
                    radiusY: 8
                }
                PathLine {
                    x: balloon.width - 0.5
                    y: balloon.bodyHeight - 8
                }
                PathArc {
                    x: balloon.width - 8.5
                    y: balloon.bodyHeight
                    radiusX: 8
                    radiusY: 8
                }
                PathLine {
                    x: balloon.tip + 8
                    y: balloon.bodyHeight
                }
                PathLine {
                    x: balloon.tip
                    y: balloon.bodyHeight + balloon.tail - 0.5
                }
                PathLine {
                    x: balloon.tip - 16
                    y: balloon.bodyHeight
                }
                PathLine {
                    x: 8.5
                    y: balloon.bodyHeight
                }
                PathArc {
                    x: 0.5
                    y: balloon.bodyHeight - 8
                    radiusX: 8
                    radiusY: 8
                }
                PathLine {
                    x: 0.5
                    y: 8.5
                }
                PathArc {
                    x: 8.5
                    y: 0.5
                    radiusX: 8
                    radiusY: 8
                }
            }
        }

        ColumnLayout {
            id: content

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 10
            spacing: 6

            Text {
                Layout.fillWidth: true
                text: root.message?.summary ?? ""
                visible: text !== ""
                color: balloon.popup.text
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                font.family: Theme.fontSans
                font.pixelSize: Theme.fontSize - 1
                font.bold: true
            }

            Text {
                Layout.fillWidth: true
                text: root.message?.body ?? ""
                visible: text !== ""
                textFormat: Text.PlainText
                color: balloon.popup.text
                wrapMode: Text.Wrap
                maximumLineCount: 6
                elide: Text.ElideRight
                font.family: Theme.fontSans
                font.pixelSize: Theme.fontSize - 1
            }
        }
    }
}
