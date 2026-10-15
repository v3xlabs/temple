pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets

// Windows XP's Date and Time Properties (timedate.cpl), which XP opens from
// the taskbar clock. The frame and controls are luna.msstyles bitmaps from
// /etc/temple/luna and the world map is timedate.cpl's own, from
// /etc/temple/timedate. Positions are the dialog units of timedate.cpl's
// templates at Tahoma 8: 1.5 px across and 1.625 px down per unit.
// Apply and OK set the clock and NTP through systemctl and the temple-set-time@ unit; polkit asks once.
PanelWindow {
    id: root

    readonly property string luna: "file:///etc/temple/luna/"
    property bool open: false
    property int tab: 0
    property point position
    // The month the calendar shows and the day it marks.
    property int year: 2000
    property int month: 0
    property int day: 1
    property string focusedControl: "month"
    property var timedate: ({})
    // The time field keeps running from the time typed into it.
    property bool timeEdited: false
    property date editedTime
    property date editedAt
    // hour, minute, second or ampm: the part of the time field the spinner steps.
    property string timePart: "hour"
    // The Internet Time check box, once clicked; null follows timedatectl.
    property var ntpChoice: null
    property bool applying: false
    property bool closeAfterApply: false
    property string failure: ""

    readonly property date now: clock.date
    readonly property date shownTime: root.timeEdited ? new Date(root.editedTime.getTime() + root.now.getTime() - root.editedAt.getTime()) : root.now
    readonly property var monthNames: Array.from({
        length: 12
    }, (_, index) => Qt.locale().standaloneMonthName(index, Locale.LongFormat))
    readonly property int firstWeekday: Qt.locale().firstDayOfWeek % 7
    readonly property int daysInMonth: new Date(root.year, root.month + 1, 0).getDate()
    readonly property int leadingBlanks: (new Date(root.year, root.month, 1).getDay() - root.firstWeekday + 7) % 7
    readonly property int januaryOffset: -new Date(root.now.getFullYear(), 0, 1).getTimezoneOffset()
    readonly property int julyOffset: -new Date(root.now.getFullYear(), 6, 1).getTimezoneOffset()
    readonly property bool observesDst: root.januaryOffset !== root.julyOffset
    readonly property bool ntpOn: root.timedate.Active === "active"
    readonly property bool timePending: root.timeEdited || root.year !== root.now.getFullYear() || root.month !== root.now.getMonth() || root.day !== root.now.getDate()
    // timedated refuses set-time while NTP runs, so a new time turns NTP off.
    readonly property bool ntpWanted: root.timePending ? false : root.ntpChoice ?? root.ntpOn
    readonly property bool pending: root.timePending || root.ntpWanted !== root.ntpOn
    readonly property var timeParts: {
        const t = root.shownTime;
        const pad = value => String(value).padStart(2, "0");
        return [["hour", String(t.getHours() % 12 || 12)], ["", ":"], ["minute", pad(t.getMinutes())], ["", ":"], ["second", pad(t.getSeconds())], ["", " "], ["ampm", t.getHours() < 12 ? "AM" : "PM"]];
    }

    function show(target: ShellScreen) {
        if (!open) {
            screen = target;
            const today = new Date();
            year = today.getFullYear();
            month = today.getMonth();
            day = today.getDate();
            tab = 0;
            focusedControl = "month";
            timeEdited = false;
            ntpChoice = null;
            failure = "";
            position = Qt.point(Math.round((target.width - implicitWidth) / 2), Math.round((target.height - implicitHeight) / 2));
            open = true;
            status.running = true;
        }
        keys.forceActiveFocus();
    }

    function stepTime(delta: int) {
        const t = new Date(shownTime.getTime());
        if (timePart === "hour")
            t.setHours((t.getHours() + delta + 24) % 24);
        else if (timePart === "minute")
            t.setMinutes((t.getMinutes() + delta + 60) % 60);
        else if (timePart === "second")
            t.setSeconds((t.getSeconds() + delta + 60) % 60);
        else
            t.setHours((t.getHours() + 12) % 24);
        editedTime = t;
        editedAt = new Date();
        timeEdited = true;
        focusedControl = "time";
    }

    // The arrow keys step the focused control, as they do in XP.
    function step(delta: int) {
        if (focusedControl === "time")
            stepTime(delta);
        else if (focusedControl === "year")
            showMonth(year + delta, month);
        else if (focusedControl === "month")
            showMonth(year, (month + 12 - delta) % 12);
    }

    // Apply: a new date or time starts temple-set-time@, the NixOS module's unit that stops NTP
    // and runs `timedatectl set-time`; otherwise the check box starts or stops timesyncd.
    // Both are systemctl calls, one polkit action, so polkit asks once.
    function apply(thenClose: bool) {
        if (!pending) {
            if (thenClose)
                close();
            return;
        }
        const pad = value => String(value).padStart(2, "0");
        const t = shownTime;
        closeAfterApply = thenClose;
        applying = true;
        setter.command = timePending ? ["sh", "-c", 'systemctl start "temple-set-time@$(systemd-escape -- "$1").service" 2>&1; echo "exit=$?"', "sh", `${year}-${pad(month + 1)}-${pad(day)} ${pad(t.getHours())}:${pad(t.getMinutes())}:${pad(t.getSeconds())}`] : ["sh", "-c", 'systemctl "$1" systemd-timesyncd.service 2>&1; echo "exit=$?"', "sh", ntpWanted ? "start" : "stop"];
        setter.running = true;
    }

    function applied(output: string) {
        applying = false;
        const lines = output.trim().split("\n");
        const code = lines.pop();
        if (code === "exit=0") {
            timeEdited = false;
            ntpChoice = null;
            const today = new Date();
            year = today.getFullYear();
            month = today.getMonth();
            day = today.getDate();
            status.running = true;
            if (closeAfterApply)
                close();
            return;
        }
        const message = lines.join(" ");
        failure = /denied|not authorized|authentication/i.test(message) ? "You do not have the proper privilege level to change the System Time." : message;
    }

    function close() {
        monthList.visible = false;
        open = false;
    }

    function showMonth(newYear: int, newMonth: int) {
        year = newYear;
        month = newMonth;
        day = Math.min(day, new Date(newYear, newMonth + 1, 0).getDate());
    }

    // XP names a zone by its standard offset, so a summer date still reads as the winter one.
    function zoneLabel(): string {
        const minutes = Math.min(januaryOffset, julyOffset);
        const hours = String(Math.floor(Math.abs(minutes) / 60)).padStart(2, "0");
        const rest = String(Math.abs(minutes) % 60).padStart(2, "0");
        return `(GMT${minutes < 0 ? "-" : "+"}${hours}:${rest}) ${timedate.Timezone ?? ""}`;
    }

    visible: open
    WlrLayershell.namespace: "temple-datetime"
    // The polkit prompt is a normal window, so the dialog drops below windows while timedatectl waits on it.
    WlrLayershell.layer: root.applying ? WlrLayer.Bottom : WlrLayer.Top
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors {
        top: true
        left: true
    }
    margins {
        left: root.position.x
        top: root.position.y
    }
    implicitWidth: client.width + 8
    implicitHeight: client.height + 33
    color: "transparent"

    SystemClock {
        id: clock

        enabled: root.open
        precision: SystemClock.Seconds
    }

    FontLoader {
        id: tahoma

        source: "../bar/assets/xp-tahoma.ttf"
    }

    // One Key=value line per fact. `timedatectl show-timesync` would start timesyncd
    // through D-Bus activation, so the unit state comes from systemctl and the server
    // from timesyncd.conf: the first NTP= server, else the first FallbackNTP= one, as
    // timesyncd picks them. NixOS sets only FallbackNTP= by default.
    Process {
        id: status

        command: ["sh", "-c", "timedatectl show -p Timezone -p NTPSynchronized; echo \"Active=$(systemctl is-active systemd-timesyncd.service)\"; awk -F= '$1 == \"NTP\" { split($2, s, \" \"); ntp = s[1] } $1 == \"FallbackNTP\" { split($2, s, \" \"); fallback = s[1] } END { print \"ServerName=\" (ntp != \"\" ? ntp : fallback) }' /etc/systemd/timesyncd.conf 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: root.timedate = text.trim().split("\n").reduce((entries, line) => {
                const split = line.indexOf("=");
                entries[line.slice(0, split)] = line.slice(split + 1);
                return entries;
            }, {})
        }
    }

    Process {
        id: setter

        stdout: StdioCollector {
            onStreamFinished: root.applied(text)
        }
    }

    component Label: Text {
        color: enabled ? "#000000" : "#a1a192"
        renderType: Text.NativeRendering
        font.family: tahoma.name
        font.pixelSize: 11
        font.hintingPreference: Font.PreferFullHinting
    }

    component PushButton: BorderImage {
        id: button

        property string label
        property bool isDefault: false

        signal clicked

        width: 75
        height: 23
        source: root.luna + "dialog/button-" + (!button.enabled ? "disabled" : buttonArea.pressed ? "pressed" : buttonArea.containsMouse ? "hot" : button.isDefault ? "default" : "normal") + ".png"
        border.left: 8
        border.right: 8
        border.top: 9
        border.bottom: 9
        smooth: false

        Label {
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: buttonArea.pressed ? 1 : 0
            anchors.verticalCenterOffset: buttonArea.pressed ? 1 : 0
            enabled: button.enabled
            text: button.label
        }

        MouseArea {
            id: buttonArea

            anchors.fill: parent
            hoverEnabled: true
            onClicked: button.clicked()
        }
    }

    // A field in Luna's blue-grey edit border, beige when disabled.
    component Field: Rectangle {
        color: enabled ? "#ffffff" : "#f5f4ea"
        border.width: 1
        border.color: enabled ? "#7f9db9" : "#c9c7ba"
    }

    component Spin: Column {
        id: spin

        property bool interactive: false

        signal stepped(int delta)

        width: 15

        Repeater {
            model: ["up", "down"]

            BorderImage {
                id: half

                required property string modelData
                readonly property string look: spinArea.pressed ? "pressed" : spinArea.containsMouse ? "hot" : "normal"

                width: spin.width
                height: half.modelData === "up" ? 10 : 11
                source: root.luna + "dialog/spin" + half.modelData + "-" + half.look + ".png"
                border.left: 4
                border.right: 4
                border.top: 4
                border.bottom: 4
                smooth: false

                Image {
                    anchors.centerIn: parent
                    source: root.luna + "dialog/spin" + half.modelData + "-glyph-" + half.look + ".png"
                    smooth: false
                }

                MouseArea {
                    id: spinArea

                    anchors.fill: parent
                    enabled: spin.interactive
                    hoverEnabled: true
                    onClicked: spin.stepped(half.modelData === "up" ? 1 : -1)
                }
            }
        }
    }

    // A drop-down list's closed face. Only an interactive one answers the pointer.
    component ComboBox: Field {
        id: combo

        property string text
        property bool highlighted: false
        property bool interactive: false

        signal opened

        height: 21

        Rectangle {
            x: 3
            anchors.verticalCenter: parent.verticalCenter
            width: comboText.implicitWidth + 2
            height: comboText.implicitHeight + 1
            color: combo.highlighted ? "#316ac5" : "transparent"

            Label {
                id: comboText

                x: 1
                enabled: combo.enabled
                text: combo.text
                color: combo.highlighted ? "#ffffff" : enabled ? "#000000" : "#a1a192"
            }
        }

        BorderImage {
            id: dropButton

            readonly property string look: !combo.enabled ? "disabled" : comboArea.pressed ? "pressed" : comboArea.containsMouse ? "hot" : "normal"

            x: parent.width - width - 1
            y: 1
            width: 17
            height: parent.height - 2
            source: root.luna + "dialog/combo-" + dropButton.look + ".png"
            border.left: 3
            border.right: 3
            border.top: 3
            border.bottom: 3
            smooth: false

            Image {
                anchors.centerIn: parent
                source: root.luna + "dialog/combo-glyph-" + dropButton.look + ".png"
                smooth: false
            }
        }

        MouseArea {
            id: comboArea

            anchors.fill: parent
            enabled: combo.interactive
            hoverEnabled: true
            onClicked: combo.opened()
        }
    }

    component CheckBox: Item {
        id: check

        property string label
        property bool checked: false
        property bool interactive: false
        readonly property string look: !check.enabled ? "-disabled" : checkArea.pressed ? "-pressed" : checkArea.containsMouse ? "-hot" : ""

        signal toggled

        implicitWidth: checkRow.implicitWidth
        implicitHeight: checkRow.implicitHeight

        Row {
            id: checkRow

            spacing: 5

            Image {
                anchors.verticalCenter: parent.verticalCenter
                source: root.luna + "dialog/checkbox-" + (check.checked ? "checked" : "unchecked") + check.look + ".png"
                smooth: false
            }

            Label {
                anchors.verticalCenter: parent.verticalCenter
                enabled: check.enabled
                text: check.label
            }
        }

        MouseArea {
            id: checkArea

            anchors.fill: parent
            enabled: check.interactive
            hoverEnabled: true
            onClicked: check.toggled()
        }
    }

    // The tab page gradient, true size from the top of the page; the group
    // labels clear their stretch of the group frame with the same rows.
    component PageBody: Image {
        source: root.luna + "dialog/tabbody-normal.png"
        fillMode: Image.Stretch
        smooth: false
    }

    component GroupBox: Item {
        id: group

        property string title
        default property alias content: groupContent.data

        BorderImage {
            anchors.fill: parent
            anchors.topMargin: 6
            source: root.luna + "dialog/groupbox-normal.png"
            border.left: 4
            border.right: 4
            border.top: 4
            border.bottom: 4
            horizontalTileMode: BorderImage.Repeat
            verticalTileMode: BorderImage.Repeat
            smooth: false
        }

        PageBody {
            x: 6
            width: groupLabel.implicitWidth + 4
            height: groupLabel.implicitHeight
            sourceClipRect: Qt.rect(0, group.y, 9, height)
        }

        Label {
            id: groupLabel

            x: 8
            text: group.title
            color: "#0046d5"
        }

        Item {
            id: groupContent

            anchors.fill: parent
        }
    }

    // timedate.cpl's clock: cyan hour studs, grey minute dots, teal hands
    // over their grey shadows, and a black second hand.
    component AnalogClock: Item {
        id: face

        readonly property real radius: width / 2

        Repeater {
            model: 60

            Item {
                id: mark

                required property int index
                readonly property real angle: mark.index * Math.PI / 30
                readonly property bool hour: mark.index % 5 === 0
                readonly property int size: mark.hour ? 4 : 2

                x: Math.round(face.radius + Math.sin(mark.angle) * (face.radius - 4) - mark.size / 2)
                y: Math.round(face.radius - Math.cos(mark.angle) * (face.radius - 4) - mark.size / 2)
                width: mark.size
                height: mark.size

                Rectangle {
                    anchors.fill: parent
                    color: mark.hour ? "#000000" : "#a0a0a0"
                }

                Rectangle {
                    visible: mark.hour
                    width: 3
                    height: 3
                    color: "#00ffff"
                }

                Rectangle {
                    visible: mark.hour
                    x: 1
                    y: 1
                    width: 2
                    height: 2
                    color: "#008080"
                }
            }
        }

        Canvas {
            id: hands

            anchors.fill: parent
            renderStrategy: Canvas.Cooperative

            Connections {
                target: clock

                function onDateChanged() {
                    hands.requestPaint();
                }
            }

            onPaint: {
                const ctx = getContext("2d");
                const r = face.radius;
                const time = root.shownTime;
                const seconds = time.getSeconds();
                const minutes = time.getMinutes() + seconds / 60;
                const hours = time.getHours() % 12 + minutes / 60;
                ctx.reset();

                // A kite: widest a little past the centre, a short tail behind it.
                const hand = (turns, length, breadth, color, dx, dy) => {
                    const angle = turns * 2 * Math.PI;
                    const ux = Math.sin(angle);
                    const uy = -Math.cos(angle);
                    const cx = r + dx;
                    const cy = r + dy;
                    const waist = length * 0.12;
                    ctx.beginPath();
                    ctx.moveTo(cx + ux * length, cy + uy * length);
                    ctx.lineTo(cx - uy * breadth + ux * waist, cy + ux * breadth + uy * waist);
                    ctx.lineTo(cx - ux * waist, cy - uy * waist);
                    ctx.lineTo(cx + uy * breadth + ux * waist, cy - ux * breadth + uy * waist);
                    ctx.closePath();
                    ctx.fillStyle = color;
                    ctx.fill();
                };
                hand(hours / 12, r * 0.6, 5, "#808080", 2, 2);
                hand(minutes / 60, r * 0.86, 4, "#808080", 2, 2);
                hand(hours / 12, r * 0.6, 5, "#008080", 0, 0);
                hand(minutes / 60, r * 0.86, 4, "#008080", 0, 0);

                const angle = seconds / 60 * 2 * Math.PI;
                ctx.beginPath();
                ctx.moveTo(r + 0.5, r + 0.5);
                ctx.lineTo(r + 0.5 + Math.sin(angle) * r * 0.86, r + 0.5 - Math.cos(angle) * r * 0.86);
                ctx.lineWidth = 1;
                ctx.strokeStyle = "#000000";
                ctx.stroke();
            }
        }
    }

    FocusScope {
        id: keys

        anchors.fill: parent
        focus: true
        // While the message box shows, Esc and Enter only dismiss it.
        Keys.onEscapePressed: root.failure !== "" ? root.failure = "" : root.close()
        Keys.onReturnPressed: root.failure !== "" ? root.failure = "" : root.apply(true)
        Keys.onEnterPressed: root.failure !== "" ? root.failure = "" : root.apply(true)
        Keys.onUpPressed: root.step(1)
        Keys.onDownPressed: root.step(-1)
    }

    BorderImage {
        width: parent.width
        height: 29
        source: root.luna + "frame/caption-active.png"
        border.left: 28
        border.right: 35
        border.top: 9
        border.bottom: 17
        smooth: false

        // The caption drags the dialog like a window title bar.
        MouseArea {
            property point pressedAt

            anchors.fill: parent
            onPressed: mouse => pressedAt = Qt.point(mouse.x, mouse.y)
            onPositionChanged: mouse => root.position = Qt.point(root.position.x + mouse.x - pressedAt.x, root.position.y + mouse.y - pressedAt.y)
        }

        Text {
            x: 9
            y: 4
            height: 25
            verticalAlignment: Text.AlignVCenter
            text: "Date and Time Properties"
            // XP draws captions in Trebuchet MS Bold; Tahoma Bold, XP's other UI face, stands in as it does in the window frame.
            font.family: "Tahoma"
            font.pixelSize: 13
            font.bold: true
            color: "#ffffff"
            style: Text.Raised
            styleColor: "#0a1883"
            renderType: Text.NativeRendering
        }

        Image {
            id: closeButton

            readonly property int frame: closeArea.pressed ? 2 : closeArea.containsMouse ? 1 : 0

            x: parent.width - 4 - width
            y: 5
            source: root.luna + "frame/close-" + closeButton.frame + ".png"
            smooth: false

            Image {
                x: 4
                y: 4
                source: root.luna + "frame/close-glyph-" + closeButton.frame + ".png"
                smooth: false
            }

            MouseArea {
                id: closeArea

                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.close()
            }
        }
    }

    Image {
        y: 29
        width: 4
        height: client.height
        source: root.luna + "frame/left-active.png"
        smooth: false
    }

    Image {
        x: parent.width - 4
        y: 29
        width: 4
        height: client.height
        source: root.luna + "frame/right-active.png"
        smooth: false
    }

    BorderImage {
        y: parent.height - 4
        width: parent.width
        height: 4
        source: root.luna + "frame/bottom-active.png"
        border.left: 5
        border.right: 5
        border.top: 2
        border.bottom: 2
        smooth: false
    }

    Rectangle {
        id: client

        x: 4
        y: 29
        width: 394
        height: 311
        color: "#ece9d8"

        // A press anywhere but on the month list closes the dropped list.
        MouseArea {
            anchors.fill: parent
            onPressed: mouse => {
                monthList.visible = false;
                mouse.accepted = false;
            }
        }

        Item {
            id: tabControl

            x: 6
            y: 6
            width: 382
            height: 262

            BorderImage {
                id: pane

                y: 21
                width: parent.width
                height: parent.height - 21
                source: root.luna + "dialog/tabpane-normal.png"
                border.left: 2
                border.right: 4
                border.top: 2
                border.bottom: 4
                smooth: false

                // The 252 x 146 unit property page.
                Item {
                    id: page

                    x: 1
                    y: 1
                    width: 378
                    height: 237
                    clip: true

                    PageBody {
                        width: parent.width
                        height: 600
                    }

                    Item {
                        anchors.fill: parent
                        visible: root.tab === 0

                        GroupBox {
                            x: 6
                            y: 3
                            width: 183
                            height: 203
                            title: "Date"

                            ComboBox {
                                id: monthCombo

                                x: 10
                                y: 25
                                width: 75
                                interactive: true
                                text: root.monthNames[root.month]
                                highlighted: root.focusedControl === "month"
                                onOpened: {
                                    root.focusedControl = "month";
                                    monthList.visible = !monthList.visible;
                                }

                                WheelHandler {
                                    onWheel: event => root.showMonth(root.year, (root.month + (event.angleDelta.y > 0 ? 11 : 1)) % 12)
                                }
                            }

                            Field {
                                x: 96
                                y: 25
                                width: 63
                                height: 21

                                Rectangle {
                                    x: 3
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: yearText.implicitWidth + 2
                                    height: yearText.implicitHeight + 1
                                    color: root.focusedControl === "year" ? "#316ac5" : "transparent"

                                    Label {
                                        id: yearText

                                        x: 1
                                        text: root.year
                                        color: root.focusedControl === "year" ? "#ffffff" : "#000000"
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: root.focusedControl = "year"
                                    onWheel: wheel => root.showMonth(root.year + (wheel.angleDelta.y > 0 ? 1 : -1), root.month)
                                }
                            }

                            Spin {
                                x: 160
                                y: 25
                                interactive: true
                                onStepped: delta => {
                                    root.focusedControl = "year";
                                    root.showMonth(root.year + delta, root.month);
                                }
                            }

                            // The month grid in a sunken client edge.
                            Rectangle {
                                x: 11
                                y: 57
                                width: 162
                                height: 130
                                color: "#aca899"

                                Rectangle {
                                    x: 1
                                    y: 1
                                    width: parent.width - 1
                                    height: parent.height - 1
                                    color: "#ffffff"

                                    Rectangle {
                                        width: parent.width - 1
                                        height: parent.height - 1
                                        color: "#716f64"

                                        Rectangle {
                                            x: 1
                                            y: 1
                                            width: parent.width - 1
                                            height: parent.height - 1
                                            color: "#f1efe2"

                                            Rectangle {
                                                id: calendar

                                                readonly property real cellWidth: width / 7

                                                width: parent.width - 1
                                                height: parent.height - 1
                                                color: "#ffffff"

                                                Rectangle {
                                                    width: parent.width
                                                    height: 18
                                                    color: "#7a96df"

                                                    Row {
                                                        Repeater {
                                                            model: 7

                                                            Label {
                                                                required property int index

                                                                width: calendar.cellWidth
                                                                height: 18
                                                                horizontalAlignment: Text.AlignHCenter
                                                                verticalAlignment: Text.AlignVCenter
                                                                text: Qt.locale().dayName((root.firstWeekday + index) % 7, Locale.NarrowFormat)
                                                                color: "#ffffff"
                                                            }
                                                        }
                                                    }
                                                }

                                                Repeater {
                                                    model: root.daysInMonth

                                                    Item {
                                                        id: cell

                                                        required property int index
                                                        readonly property int slot: root.leadingBlanks + cell.index
                                                        readonly property bool selected: cell.index + 1 === root.day

                                                        x: (cell.slot % 7) * calendar.cellWidth
                                                        y: 19 + Math.floor(cell.slot / 7) * 18
                                                        width: calendar.cellWidth
                                                        height: 18

                                                        Rectangle {
                                                            anchors.centerIn: parent
                                                            width: dayText.implicitWidth + 2
                                                            height: dayText.implicitHeight + 1
                                                            color: cell.selected ? "#316ac5" : "transparent"
                                                        }

                                                        Label {
                                                            id: dayText

                                                            anchors.centerIn: parent
                                                            text: cell.index + 1
                                                            color: cell.selected ? "#ffffff" : "#000000"
                                                        }

                                                        MouseArea {
                                                            anchors.fill: parent
                                                            onClicked: {
                                                                root.focusedControl = "calendar";
                                                                root.day = cell.index + 1;
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        GroupBox {
                            x: 198
                            y: 3
                            width: 170
                            height: 203
                            title: "Time"

                            AnalogClock {
                                x: 18
                                y: 23
                                width: 135
                                height: 135
                            }

                            Field {
                                x: 40
                                y: 168
                                width: 86
                                height: 20

                                Row {
                                    anchors.right: parent.right
                                    anchors.rightMargin: 4
                                    anchors.verticalCenter: parent.verticalCenter

                                    Repeater {
                                        model: root.timeParts

                                        Rectangle {
                                            id: timePart

                                            required property var modelData
                                            readonly property bool selected: root.focusedControl === "time" && root.timePart === timePart.modelData[0]

                                            width: partText.implicitWidth
                                            height: partText.implicitHeight
                                            color: timePart.selected ? "#316ac5" : "transparent"

                                            Label {
                                                id: partText

                                                text: timePart.modelData[1]
                                                color: timePart.selected ? "#ffffff" : "#000000"
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                enabled: timePart.modelData[0] !== ""
                                                onClicked: {
                                                    root.focusedControl = "time";
                                                    root.timePart = timePart.modelData[0];
                                                }
                                            }
                                        }
                                    }
                                }

                                WheelHandler {
                                    onWheel: event => root.stepTime(event.angleDelta.y > 0 ? 1 : -1)
                                }
                            }

                            Spin {
                                x: 127
                                y: 168
                                interactive: true
                                onStepped: delta => root.stepTime(delta)
                            }
                        }

                        Label {
                            x: 6
                            y: 221
                            text: "Current time zone:  " + Qt.formatDateTime(root.now, "tttt")
                        }
                    }

                    Item {
                        anchors.fill: parent
                        visible: root.tab === 1

                        ComboBox {
                            x: 7
                            y: 6
                            width: 362
                            text: root.zoneLabel()
                        }

                        Image {
                            x: 7
                            y: 36
                            width: 362
                            height: 184
                            source: "file:///etc/temple/timedate/worldmap.png"
                            fillMode: Image.PreserveAspectFit
                            smooth: false
                        }

                        CheckBox {
                            x: 7
                            y: 224
                            enabled: root.observesDst
                            checked: root.observesDst
                            label: "Automatically adjust clock for daylight saving changes"
                        }
                    }

                    Item {
                        anchors.fill: parent
                        visible: root.tab === 2

                        CheckBox {
                            x: 12
                            y: 16
                            enabled: !root.timePending
                            interactive: true
                            checked: root.ntpWanted
                            label: "Automatically synchronize with an Internet time server"
                            onToggled: root.ntpChoice = !root.ntpWanted
                        }

                        Label {
                            x: 46
                            y: 42
                            enabled: root.ntpWanted
                            text: "Server:"
                        }

                        ComboBox {
                            x: 90
                            y: 38
                            width: 172
                            enabled: root.ntpWanted
                            text: root.timedate.ServerName ?? ""
                        }

                        PushButton {
                            x: 270
                            y: 37
                            width: 83
                            enabled: false
                            label: "Update Now"
                        }

                        Label {
                            x: 12
                            y: 84
                            width: 352
                            wrapMode: Text.WordWrap
                            text: root.timedate.NTPSynchronized === "yes" ? `The time has been successfully synchronized with ${root.timedate.ServerName || "the time server"}.` : "Windows has never attempted to synchronize with an internet time server."
                        }

                        Label {
                            x: 12
                            y: 195
                            width: 352
                            wrapMode: Text.WordWrap
                            text: "Synchronization can occur only when your computer is connected to the Internet."
                        }
                    }
                }
            }

            Row {
                x: 2

                Repeater {
                    model: ["Date & Time", "Time Zone", "Internet Time"]

                    BorderImage {
                        id: tabItem

                        required property string modelData
                        required property int index
                        readonly property bool selected: tabItem.index === root.tab

                        // The selected tab stands two pixels taller and covers the pane edge below it.
                        y: tabItem.selected ? 0 : 2
                        width: tabLabel.implicitWidth + (tabItem.selected ? 18 : 14)
                        height: tabItem.selected ? 23 : 19
                        source: root.luna + "dialog/" + (tabItem.selected ? "tab-top" : "tab") + (tabItem.index === 0 ? "-left" : "") + "-" + (tabItem.selected ? "selected" : tabArea.containsMouse ? "hot" : "normal") + ".png"
                        border.left: 6
                        border.right: 6
                        border.top: 6
                        border.bottom: 6
                        z: tabItem.selected ? 1 : 0
                        smooth: false

                        Label {
                            id: tabLabel

                            anchors.centerIn: parent
                            anchors.verticalCenterOffset: tabItem.selected ? -1 : 0
                            text: tabItem.modelData
                        }

                        MouseArea {
                            id: tabArea

                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                monthList.visible = false;
                                root.tab = tabItem.index;
                            }
                        }
                    }
                }
            }
        }

        PushButton {
            x: 151
            y: 281
            enabled: !root.applying
            label: "OK"
            isDefault: true
            onClicked: root.apply(true)
        }

        PushButton {
            x: 232
            y: 281
            enabled: !root.applying
            label: "Cancel"
            onClicked: root.close()
        }

        PushButton {
            x: 313
            y: 281
            enabled: root.pending && !root.applying
            label: "Apply"
            onClicked: root.apply(false)
        }

        // The dropped month list of the month combo box.
        Rectangle {
            id: monthList

            readonly property point origin: monthCombo.mapToItem(client, 0, monthCombo.height)

            visible: false
            x: monthList.origin.x
            y: monthList.origin.y
            width: monthCombo.width
            height: monthColumn.height + 2
            color: "#ffffff"
            border.width: 1
            border.color: "#000000"

            Column {
                id: monthColumn

                readonly property bool hovered: monthHover.hovered

                x: 1
                y: 1
                width: parent.width - 2

                HoverHandler {
                    id: monthHover
                }

                Repeater {
                    model: root.monthNames

                    Rectangle {
                        id: monthRow

                        required property string modelData
                        required property int index
                        readonly property bool lit: monthArea.containsMouse || (!monthColumn.hovered && monthRow.index === root.month)

                        width: monthColumn.width
                        height: 13
                        color: monthRow.lit ? "#316ac5" : "#ffffff"

                        Label {
                            x: 2
                            anchors.verticalCenter: parent.verticalCenter
                            text: monthRow.modelData
                            color: monthRow.lit ? "#ffffff" : "#000000"
                        }

                        MouseArea {
                            id: monthArea

                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                root.showMonth(root.year, monthRow.index);
                                monthList.visible = false;
                            }
                        }
                    }
                }
            }
        }

        // XP's message box for a clock that could not be set, modal over the dialog.
        MouseArea {
            anchors.fill: parent
            visible: root.failure !== ""

            Rectangle {
                anchors.centerIn: parent
                width: 300
                height: 29 + messageBody.implicitHeight + 3
                color: "#ece9d8"
                border.width: 1
                border.color: "#0831d9"

                BorderImage {
                    width: parent.width
                    height: 29
                    source: root.luna + "frame/caption-active.png"
                    border.left: 28
                    border.right: 35
                    border.top: 9
                    border.bottom: 17
                    smooth: false

                    Text {
                        x: 9
                        y: 4
                        height: 25
                        verticalAlignment: Text.AlignVCenter
                        text: "Date and Time Properties"
                        font.family: "Tahoma"
                        font.pixelSize: 13
                        font.bold: true
                        color: "#ffffff"
                        style: Text.Raised
                        styleColor: "#0a1883"
                        renderType: Text.NativeRendering
                    }
                }

                Column {
                    id: messageBody

                    x: 12
                    y: 29 + 12
                    width: parent.width - 24
                    spacing: 14

                    Row {
                        spacing: 12

                        IconImage {
                            implicitSize: 32
                            source: Quickshell.iconPath("dialog-error")
                        }

                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            width: messageBody.width - 44
                            wrapMode: Text.WordWrap
                            text: root.failure
                        }
                    }

                    PushButton {
                        anchors.horizontalCenter: parent.horizontalCenter
                        label: "OK"
                        isDefault: true
                        onClicked: root.failure = ""
                    }

                    Item {
                        width: 1
                        height: 1
                    }
                }
            }
        }
    }
}
