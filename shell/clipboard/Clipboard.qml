pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import org.kde.kitemmodels as KItemModels
import org.kde.plasma.private.clipboard as Klipper
import "../theme"
import "../tray"
import "../windows"

// Clipboard history. Plasma's Klipper records it into the same database the
// Plasma session uses. Picking an entry moves it to the top of the history,
// which puts it back on the clipboard.
PanelWindow {
    id: root

    property bool open: false

    // The screen is taken once, as in the pickers: the flyout takes the
    // keyboard, which changes the focused screen.
    function toggle() {
        if (!open)
            screen = Windows.focusedScreen;
        open = !open;
    }

    function pick(uuid: string) {
        history.moveToTop(uuid);
        open = false;
    }

    visible: open
    WlrLayershell.namespace: "temple-clipboard"
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

    Klipper.HistoryModel {
        id: history
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.open = false
    }

    // A fresh flyout per open starts with an empty filter and the newest entry selected.
    Loader {
        anchors.centerIn: parent
        active: root.open
        sourceComponent: flyout
    }

    Component {
        id: flyout

        TrayFrame {
            id: panel

            readonly property int padding: TrayStyle.popup.padding

            width: 420
            height: column.implicitHeight + panel.padding * 2
            title: "Clipboard"

            MouseArea {
                anchors.fill: parent
            }

            KItemModels.KSortFilterProxyModel {
                id: matches

                sourceModel: history
                filterRoleName: "display"
                filterString: query.text
                filterCaseSensitivity: Qt.CaseInsensitive
            }

            Column {
                id: column

                x: panel.padding
                y: panel.padding
                width: panel.width - panel.padding * 2
                spacing: 4

                TextInput {
                    id: query

                    width: parent.width
                    height: 26
                    leftPadding: 6
                    rightPadding: 6
                    verticalAlignment: TextInput.AlignVCenter
                    clip: true
                    color: TrayStyle.text
                    selectionColor: TrayStyle.accent
                    font.family: TrayStyle.font
                    font.pixelSize: TrayStyle.fontSize
                    Component.onCompleted: forceActiveFocus()
                    onTextChanged: list.currentIndex = 0
                    Keys.onEscapePressed: root.open = false
                    Keys.onUpPressed: list.decrementCurrentIndex()
                    Keys.onDownPressed: list.incrementCurrentIndex()
                    Keys.onReturnPressed: {
                        if (list.currentItem)
                            root.pick(list.currentItem.uuid);
                    }

                    Text {
                        anchors.fill: parent
                        leftPadding: 6
                        verticalAlignment: Text.AlignVCenter
                        visible: query.text === ""
                        text: "Type to search"
                        color: TrayStyle.textMuted
                        font: query.font
                    }
                }

                Rectangle {
                    width: parent.width
                    height: Theme.lineWidth
                    color: TrayStyle.separator
                }

                Text {
                    visible: list.count === 0
                    width: parent.width
                    height: 48
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: history.count === 0 ? "The clipboard history is empty" : "No entry matches"
                    color: TrayStyle.textMuted
                    font.family: TrayStyle.font
                    font.pixelSize: TrayStyle.fontSize
                }

                Item {
                    visible: list.count > 0
                    width: parent.width
                    height: list.height

                    ListView {
                        id: list

                        width: parent.width
                        height: Math.min(list.contentHeight, 440)
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        model: matches

                        delegate: Rectangle {
                            id: entry

                            required property string display
                            required property url decoration
                            required property string uuid

                            readonly property bool image: entry.decoration.toString() !== ""
                            readonly property bool selected: ListView.isCurrentItem
                            readonly property color textColor: entry.selected ? TrayStyle.hoverText : TrayStyle.text

                            width: list.width
                            height: entry.image ? 56 : Math.max(label.implicitHeight + 8, 24)
                            radius: TrayStyle.rowRadius
                            color: entry.selected ? TrayStyle.hover : "transparent"
                            border.width: entry.selected && TrayStyle.hoverBorder.a > 0 ? 1 : 0
                            border.color: TrayStyle.hoverBorder

                            Image {
                                id: thumbnail

                                visible: entry.image
                                x: 6
                                anchors.verticalCenter: parent.verticalCenter
                                width: entry.image ? 80 : 0
                                height: 48
                                source: entry.decoration
                                sourceSize.height: 96
                                fillMode: Image.PreserveAspectFit
                                horizontalAlignment: Image.AlignLeft
                                asynchronous: true
                            }

                            Text {
                                id: label

                                anchors.left: thumbnail.right
                                anchors.leftMargin: entry.image ? 6 : 0
                                anchors.right: parent.right
                                anchors.rightMargin: 6
                                anchors.verticalCenter: parent.verticalCenter
                                // Entries can be megabytes long; only the start shows.
                                text: entry.display.slice(0, 300).replace(/\s+/g, " ").trim()
                                elide: Text.ElideRight
                                color: entry.textColor
                                font.family: TrayStyle.font
                                font.pixelSize: TrayStyle.fontSize
                            }
                        }
                    }

                    // The flyout opens under the resting pointer, and Wayland reports
                    // that spot as a motion. The first report only marks the spot;
                    // a move away from it selects a row.
                    MouseArea {
                        property point rest: Qt.point(-1, -1)

                        function rowAt(x: real, y: real): int {
                            return list.indexAt(x + list.contentX, y + list.contentY);
                        }

                        anchors.fill: list
                        hoverEnabled: true
                        onPositionChanged: mouse => {
                            if (rest.x < 0) {
                                rest = Qt.point(mouse.x, mouse.y);
                                return;
                            }
                            const row = rowAt(mouse.x, mouse.y);
                            if ((mouse.x !== rest.x || mouse.y !== rest.y) && row >= 0)
                                list.currentIndex = row;
                        }
                        onClicked: mouse => {
                            const row = rowAt(mouse.x, mouse.y);
                            if (row >= 0)
                                root.pick(list.itemAtIndex(row).uuid);
                        }
                    }
                }
            }
        }
    }
}
