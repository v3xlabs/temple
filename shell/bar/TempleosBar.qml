pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import Quickshell.Widgets
import "../theme"
import "../activate"
import "../config"
import "../tray"
import "../notifications"
import "../windows"

// The status line TempleOS prints on the top text row (Adam/WallPaper.HC):
// date, time, free memory in hex and the load of each CPU, white on blue,
// with the loads of odd and even cores in alternating white and yellow.
PanelWindow {
    id: bar

    property bool startOpen: false

    signal startRequested

    readonly property var tokens: Theme.barTokens.templeos
    readonly property color background: bar.tokens.color
    readonly property color textColor: bar.tokens.text
    readonly property color highlight: bar.tokens.highlight

    // Per-core load in percent, from the deltas of /proc/stat between reads.
    property var loads: []
    property var lastTimes: []
    property real memAvailable: 0

    function hex(value: real, digits: int): string {
        return Math.max(0, Math.floor(value)).toString(16).toUpperCase().padStart(digits, "0");
    }

    function readStat(text: string) {
        const times = text.split("\n").filter(line => /^cpu\d+ /.test(line)).map(line => {
            const fields = line.trim().split(/\s+/).slice(1, 9).map(Number);
            return {
                idle: fields[3] + fields[4],
                total: fields.reduce((sum, field) => sum + field, 0)
            };
        });
        bar.loads = times.map((time, index) => {
            const last = bar.lastTimes[index];
            const total = last ? time.total - last.total : 0;
            return total > 0 ? 100 * (1 - (time.idle - last.idle) / total) : 0;
        });
        bar.lastTimes = times;
    }

    function readMeminfo(text: string) {
        const match = /^MemAvailable:\s+(\d+) kB/m.exec(text);
        if (match)
            bar.memAvailable = Number(match[1]) * 1024;
    }

    WlrLayershell.namespace: "temple-bar"

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: bar.tokens.height
    color: bar.background

    FileView {
        id: stat

        path: "/proc/stat"
        onLoaded: bar.readStat(stat.text())
    }

    FileView {
        id: meminfo

        path: "/proc/meminfo"
        onLoaded: bar.readMeminfo(meminfo.text())
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            stat.reload();
            meminfo.reload();
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    Row {
        id: left

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: tray.left
        anchors.rightMargin: 16
        clip: true

        Entry {
            text: "MENU"
            active: bar.startOpen
            onClicked: bar.startRequested()
        }

        Cell {
            text: " " + Qt.formatDateTime(clock.date, "ddd MM/dd HH:mm:ss") + " Mem:" + bar.hex(bar.memAvailable, 10) + " CPU"
        }

        Repeater {
            model: bar.loads

            Cell {
                required property real modelData
                required property int index

                text: String(Math.min(99, Math.floor(modelData))).padStart(2, " ")
                color: index % 2 === 0 ? bar.highlight : bar.textColor
            }
        }

        Repeater {
            model: ScriptModel {
                values: Windows.windows.filter(toplevel => toplevel.monitor?.name === bar.screen.name)
            }

            Entry {
                id: task

                required property HyprlandToplevel modelData

                readonly property string title: task.modelData.title.length > 18 ? task.modelData.title.slice(0, 17) + "~" : task.modelData.title

                text: " " + (Windows.minimized(task.modelData) ? "(" + task.title + ")" : task.title) + " "
                active: task.modelData.activated
                middleClose: true
                onClicked: Windows.click(task.modelData)
                onMiddleClicked: task.modelData.wayland?.close()
            }
        }
    }

    Row {
        id: tray

        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        spacing: 16

        NotificationBell {
            anchors.verticalCenter: parent.verticalCenter
            size: 16
        }

        Network {
            anchors.verticalCenter: parent.verticalCenter
            size: 16
        }

        Volume {
            anchors.verticalCenter: parent.verticalCenter
            size: 16
        }

        Entry {
            visible: Config.activateLinux
            text: ActivateLinux.shown ? "Act:On" : "Act:Off"
            onClicked: ActivateLinux.toggle()
        }

        Repeater {
            model: SystemTray.items

            Item {
                id: trayItem

                required property SystemTrayItem modelData

                width: 16
                height: 16

                IconImage {
                    anchors.fill: parent
                    source: trayItem.modelData.icon
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                    onClicked: mouse => {
                        const item = trayItem.modelData;
                        if (mouse.button === Qt.MiddleButton) {
                            item.secondaryActivate();
                        } else if (mouse.button === Qt.LeftButton && !item.onlyMenu) {
                            item.activate();
                        } else if (item.hasMenu) {
                            const position = trayItem.mapToItem(null, 0, 0);
                            item.display(bar, position.x, position.y + trayItem.height);
                        }
                    }
                    onWheel: wheel => trayItem.modelData.scroll(wheel.angleDelta.y, false)
                }
            }
        }

        // TempleOS keeps the last text column free.
        Item {
            width: 1
            height: 16
        }
    }

    component Cell: Text {
        height: bar.height
        verticalAlignment: Text.AlignVCenter
        color: bar.textColor
        font.family: Theme.fontSans
        font.pixelSize: Theme.fontSize
    }

    // A menu-bar entry: yellow on blue, inverted under the mouse like the TempleOS pull-down menu.
    component Entry: Cell {
        id: entry

        property bool active: false
        property bool middleClose: false

        signal clicked
        signal middleClicked

        readonly property bool lit: entryMouse.containsMouse || entry.active

        color: entry.lit ? bar.background : bar.highlight

        Rectangle {
            z: -1
            anchors.fill: parent
            color: bar.highlight
            visible: entry.lit
        }

        MouseArea {
            id: entryMouse

            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: entry.middleClose ? Qt.LeftButton | Qt.MiddleButton : Qt.LeftButton
            onClicked: mouse => {
                if (mouse.button === Qt.MiddleButton)
                    entry.middleClicked();
                else
                    entry.clicked();
            }
        }
    }
}
