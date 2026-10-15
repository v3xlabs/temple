pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../tray"

// The Windows 7 clock flyout: the long date as a link back to today, the
// month grid that zooms out to a year and a decade, the analog clock with the
// time and weekday under it, and the link to the date and time settings.
// It lays out on the white sheet the tray flyout frame draws inside the
// glass; the analog clock and the boxes of the calendar keep Windows 7's
// own colours.
TrayPopup {
    id: popup

    // month, year or decade
    property string zoom: "month"
    property int year: 2000
    property int month: 0

    readonly property date now: clock.date
    readonly property int firstWeekday: Qt.locale().firstDayOfWeek % 7
    readonly property int decade: Math.floor(popup.year / 10) * 10

    function open() {
        if (!visible)
            today();
        toggle();
    }

    function today() {
        const now = new Date();
        year = now.getFullYear();
        month = now.getMonth();
        zoom = "month";
    }

    function step(delta: int) {
        if (zoom === "month") {
            const shown = new Date(year, month + delta, 1);
            year = shown.getFullYear();
            month = shown.getMonth();
        } else {
            year += delta * (zoom === "year" ? 1 : 10);
        }
    }

    // The 42 days of six weeks around the month, starting on the locale's first weekday.
    function monthDays(): var {
        const first = new Date(year, month, 1);
        const lead = (first.getDay() - firstWeekday + 7) % 7;
        return Array.from({
            length: 42
        }, (_, index) => new Date(year, month, 1 - lead + index));
    }

    // A theme switch away from Windows 7 hands over tokens without a sheet before the bar goes.
    padding: (TrayStyle.popup.sheet?.inset ?? 0) + 1
    panelWidth: sheet.width + padding * 2

    SystemClock {
        id: clock

        enabled: popup.visible
        precision: SystemClock.Seconds
    }

    FontLoader {
        id: segoe

        source: "../bar/assets/win7-segoe-ui.ttf"
    }

    component Label: Text {
        color: TrayStyle.text
        renderType: Text.NativeRendering
        font.family: segoe.name
        font.pixelSize: 12
        font.hintingPreference: Font.PreferFullHinting
    }

    component Link: Label {
        id: link

        signal activated

        color: TrayStyle.link
        font.underline: linkArea.containsMouse

        MouseArea {
            id: linkArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: link.activated()
        }
    }

    // A calendar cell: a light blue box under the pointer, and the blue box round today.
    component Cell: Rectangle {
        id: cell

        property string label
        property bool current: false
        property bool outside: false

        signal activated

        radius: 2
        border.width: cell.current || cellArea.containsMouse ? 1 : 0
        border.color: cell.current ? "#0066cc" : TrayStyle.hoverBorder
        gradient: Gradient {
            GradientStop {
                position: 0
                color: cell.current ? "#e6f1ff" : cellArea.containsMouse ? TrayStyle.hover : "transparent"
            }
            GradientStop {
                position: 1
                color: cell.current ? "#d2e6ff" : cellArea.containsMouse ? TrayStyle.hover : "transparent"
            }
        }

        Label {
            anchors.centerIn: parent
            text: cell.label
            color: cell.outside ? TrayStyle.textMuted : TrayStyle.text
        }

        MouseArea {
            id: cellArea

            anchors.fill: parent
            hoverEnabled: true
            onClicked: cell.activated()
        }
    }

    component Arrow: Item {
        id: arrow

        property bool pointsLeft: false

        signal activated

        width: 16
        height: 16

        // A triangle of one pixel columns, its tip on the side it points to.
        Repeater {
            model: 4

            Rectangle {
                required property int index

                anchors.verticalCenter: parent.verticalCenter
                x: arrow.pointsLeft ? 6 + index : 9 - index
                width: 1
                height: 1 + index * 2
                color: arrowArea.containsMouse ? TrayStyle.accent : TrayStyle.text
            }
        }

        MouseArea {
            id: arrowArea

            anchors.fill: parent
            hoverEnabled: true
            onClicked: arrow.activated()
        }
    }

    // The Windows 7 clock: a brushed bezel round a white face, slate hour
    // ticks and minute dots, dark hands and a thin second hand.
    component AnalogClock: Item {
        id: face

        readonly property real radius: width / 2

        Rectangle {
            anchors.fill: parent
            radius: face.radius
            border.width: 1
            border.color: "#7f8891"
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: "#fbfcfd"
                }
                GradientStop {
                    position: 1
                    color: "#9aa3ab"
                }
            }
        }

        Rectangle {
            anchors.centerIn: parent
            width: parent.width - 10
            height: width
            radius: width / 2
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: "#8f98a1"
                }
                GradientStop {
                    position: 1
                    color: "#f4f6f8"
                }
            }
        }

        Rectangle {
            anchors.centerIn: parent
            width: parent.width - 14
            height: width
            radius: width / 2
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: "#ffffff"
                }
                GradientStop {
                    position: 1
                    color: "#e6eaed"
                }
            }
        }

        // The glassy sheen: the lower right half of the face sits a shade darker.
        Rectangle {
            anchors.centerIn: parent
            width: parent.width - 14
            height: width
            radius: width / 2
            rotation: -35
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: "#00ffffff"
                }
                GradientStop {
                    position: 0.49
                    color: "#00ffffff"
                }
                GradientStop {
                    position: 0.5
                    color: "#1a6f7f8f"
                }
                GradientStop {
                    position: 1
                    color: "#086f7f8f"
                }
            }
        }

        Repeater {
            model: 60

            Rectangle {
                id: mark

                required property int index
                readonly property bool hour: mark.index % 5 === 0

                x: face.radius - width / 2
                y: 13
                width: mark.hour ? 2 : 1
                height: mark.hour ? 7 : 2
                color: mark.hour ? "#3e5265" : "#8a96a2"
                antialiasing: true
                transform: Rotation {
                    origin.x: mark.width / 2
                    origin.y: face.radius - 13
                    angle: mark.index * 6
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
                const time = popup.now;
                const seconds = time.getSeconds();
                const minutes = time.getMinutes() + seconds / 60;
                const hours = time.getHours() % 12 + minutes / 60;
                ctx.reset();
                ctx.lineCap = "round";

                const hand = (turns, length, tail, width, color) => {
                    const angle = turns * 2 * Math.PI;
                    ctx.beginPath();
                    ctx.moveTo(r - Math.sin(angle) * tail, r + Math.cos(angle) * tail);
                    ctx.lineTo(r + Math.sin(angle) * length, r - Math.cos(angle) * length);
                    ctx.lineWidth = width;
                    ctx.strokeStyle = color;
                    ctx.stroke();
                };
                hand(hours / 12, r * 0.48, 0, 3.5, "#26384a");
                hand(minutes / 60, r * 0.74, 0, 2.5, "#26384a");
                hand(seconds / 60, r * 0.78, r * 0.18, 1, "#3a4e62");

                ctx.beginPath();
                ctx.arc(r, r, 3, 0, 2 * Math.PI);
                ctx.fillStyle = "#26384a";
                ctx.fill();
            }
        }
    }

    // The content, just inside the sheet's edge.
    Item {
        id: sheet

        width: 340
        height: 280

        Link {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 16
            text: popup.now.toLocaleDateString(Qt.locale(), Locale.LongFormat)
            onActivated: popup.today()
        }

        Item {
            id: calendar

            readonly property real cellWidth: 24

            x: 14
            y: 48
            width: calendar.cellWidth * 7
            height: 162

            Arrow {
                pointsLeft: true
                onActivated: popup.step(-1)
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: title.implicitWidth + 12
                height: 18
                radius: 2
                color: titleArea.containsMouse && popup.zoom !== "decade" ? TrayStyle.hover : "transparent"
                border.width: titleArea.containsMouse && popup.zoom !== "decade" ? 1 : 0
                border.color: TrayStyle.hoverBorder

                Label {
                    id: title

                    anchors.centerIn: parent
                    text: popup.zoom === "month" ? Qt.locale().standaloneMonthName(popup.month, Locale.LongFormat) + " " + popup.year : popup.zoom === "year" ? String(popup.year) : `${popup.decade}-${popup.decade + 9}`
                }

                MouseArea {
                    id: titleArea

                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: popup.zoom = popup.zoom === "month" ? "year" : "decade"
                }
            }

            Arrow {
                anchors.right: parent.right
                onActivated: popup.step(1)
            }

            Item {
                visible: popup.zoom === "month"
                y: 22
                width: parent.width
                height: parent.height - 22

                Row {
                    Repeater {
                        model: 7

                        Label {
                            required property int index

                            width: calendar.cellWidth
                            horizontalAlignment: Text.AlignHCenter
                            text: Qt.locale().dayName((popup.firstWeekday + index) % 7, Locale.ShortFormat).slice(0, 2)
                        }
                    }
                }

                Rectangle {
                    y: 18
                    width: parent.width
                    height: 1
                    color: TrayStyle.separator
                }

                Grid {
                    y: 21
                    columns: 7

                    Repeater {
                        model: popup.monthDays()

                        Cell {
                            required property date modelData

                            width: calendar.cellWidth
                            height: 19
                            label: modelData.getDate()
                            outside: modelData.getMonth() !== popup.month
                            current: modelData.toDateString() === popup.now.toDateString()
                        }
                    }
                }
            }

            Grid {
                visible: popup.zoom !== "month"
                y: 30
                columns: 4

                Repeater {
                    model: 12

                    Cell {
                        id: zoomCell

                        required property int index
                        readonly property int value: popup.zoom === "year" ? zoomCell.index : popup.decade - 1 + zoomCell.index

                        width: calendar.width / 4
                        height: 40
                        label: popup.zoom === "year" ? Qt.locale().standaloneMonthName(zoomCell.value, Locale.ShortFormat) : String(zoomCell.value)
                        outside: popup.zoom === "decade" && (zoomCell.index === 0 || zoomCell.index === 11)
                        current: popup.zoom === "year" ? popup.year === popup.now.getFullYear() && zoomCell.value === popup.now.getMonth() : zoomCell.value === popup.now.getFullYear()
                        onActivated: {
                            if (popup.zoom === "year") {
                                popup.month = zoomCell.value;
                                popup.zoom = "month";
                            } else {
                                popup.year = zoomCell.value;
                                popup.zoom = "year";
                            }
                        }
                    }
                }
            }
        }

        AnalogClock {
            id: analog

            x: 198
            y: 54
            width: 124
            height: 124
        }

        Label {
            anchors.horizontalCenter: analog.horizontalCenter
            y: analog.y + analog.height + 8
            text: Qt.formatTime(popup.now, "h:mm:ss AP")
        }

        Label {
            anchors.horizontalCenter: analog.horizontalCenter
            y: analog.y + analog.height + 28
            text: Qt.locale().dayName(popup.now.getDay(), Locale.LongFormat)
            color: TrayStyle.textMuted
        }

        // The footer strip, shaded like the one under the volume flyout.
        Rectangle {
            y: 234
            width: parent.width
            height: parent.height - y
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: "#ccd9ea"
                }
                GradientStop {
                    position: 0.03
                    color: "#d9e3f0"
                }
                GradientStop {
                    position: 0.08
                    color: "#e8eef7"
                }
                GradientStop {
                    position: 0.15
                    color: "#f1f5fb"
                }
            }

            Link {
                anchors.centerIn: parent
                text: "Change date and time settings..."
                onActivated: {
                    popup.visible = false;
                    Quickshell.execDetached(["systemsettings", "kcm_clock"]);
                }
            }
        }
    }
}
