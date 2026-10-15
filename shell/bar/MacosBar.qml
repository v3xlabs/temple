pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import Quickshell.Widgets
import "../windows"
import "../activate"
import "../health"
import "../tray"
import "../notifications"
import "../macos"

// The macOS menu bar: Apple menu and the focused app's name on the left,
// status items and the clock on the right.
PanelWindow {
    id: bar

    property bool startOpen: false

    signal startRequested

    readonly property string appId: Windows.active?.appId ?? ""
    readonly property string appName: Windows.active === null ? "" : Windows.entry(Windows.active)?.name ?? bar.appId

    WlrLayershell.namespace: "temple-bar"
    BackgroundEffect.blurRegion: Region {
        item: bar.contentItem
    }

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Macos.height
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Macos.tint, Macos.opacity)
    }

    Row {
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.top: parent.top
        anchors.bottom: parent.bottom

        MenuTitle {
            highlighted: bar.startOpen
            text: Macos.appleLogo
            pixelSize: Macos.fontSize + 3
            horizontalPadding: 12
            onClicked: bar.startRequested()
        }

        MenuTitle {
            visible: bar.appName !== ""
            text: bar.appName
            bold: true
        }
    }

    Row {
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        spacing: 4

        Repeater {
            model: SystemTray.items

            Item {
                id: trayItem

                required property SystemTrayItem modelData

                width: 26
                height: bar.height

                Glyph {
                    anchors.centerIn: parent
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
                            const position = trayItem.mapToItem(null, 0, bar.height);
                            item.display(bar, position.x, position.y);
                        }
                    }
                    onWheel: wheel => trayItem.modelData.scroll(wheel.angleDelta.y, false)
                }
            }
        }

        HealthIcon {
            anchors.verticalCenter: parent.verticalCenter
            size: 16
        }

        ActivateToggle {
            anchors.verticalCenter: parent.verticalCenter
        }

        StatusSlot {
            Volume {
                anchors.centerIn: parent
                size: 16
            }
        }

        StatusSlot {
            Network {
                anchors.centerIn: parent
                size: 16
            }
        }

        StatusSlot {
            NotificationBell {
                id: bell

                anchors.centerIn: parent
                size: 15
            }
        }

        // The clock opens Notification Centre, as on macOS.
        MenuTitle {
            text: Qt.formatDateTime(clock.date, "ddd d MMM HH:mm")
            onClicked: bell.toggle()
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // A menu bar entry: text over a highlight that shows while its menu is open.
    component MenuTitle: Item {
        id: title

        property string text
        property bool bold: false
        property bool highlighted: false
        property int pixelSize: Macos.fontSize
        property int horizontalPadding: 9

        signal clicked

        width: label.implicitWidth + title.horizontalPadding * 2
        height: bar.height

        Rectangle {
            anchors.fill: parent
            anchors.topMargin: 2
            anchors.bottomMargin: 2
            radius: Macos.itemRadius
            color: Macos.hover
            visible: title.highlighted || area.pressed
        }

        Text {
            id: label

            anchors.centerIn: parent
            text: title.text
            color: Macos.text
            font.family: Macos.font
            font.pixelSize: title.pixelSize
            font.weight: title.bold ? Font.Bold : Font.Medium
        }

        MouseArea {
            id: area

            anchors.fill: parent
            onClicked: title.clicked()
        }
    }

    component StatusSlot: Item {
        width: 28
        height: bar.height
    }

    // Status items are monochrome glyphs in the menu bar's text colour.
    component Glyph: IconImage {
        implicitSize: 16
        layer.enabled: true
        layer.effect: MultiEffect {
            brightness: 1
            colorization: 1
            colorizationColor: Macos.text
        }
    }
}
