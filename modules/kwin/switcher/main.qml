import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.kwin as KWin
import org.kde.plasma.core as PlasmaCore

// Alt+Tab: every window, most recently used first, with live previews. KWin
// owns the key grab, so releasing Alt switches and Escape cancels. The NixOS
// module builds one package per theme around this file, with that theme's
// values in Tokens.qml.
KWin.TabBoxSwitcher {
    id: tabBox

    readonly property int cardWidth: 236
    readonly property int cardHeight: 186
    readonly property int spacing: 12
    readonly property int perRow: Math.max(1, Math.floor((screenGeometry.width - 112) / (cardWidth + spacing)))

    Tokens {
        id: tokens
    }

    Instantiator {
        active: tabBox.visible

        delegate: PlasmaCore.Dialog {
            location: PlasmaCore.Types.Floating
            backgroundHints: PlasmaCore.Dialog.NoBackground
            visible: true
            flags: Qt.Popup | Qt.X11BypassWindowManagerHint
            x: tabBox.screenGeometry.x + (tabBox.screenGeometry.width - panel.width) / 2
            y: tabBox.screenGeometry.y + (tabBox.screenGeometry.height - panel.height) / 2

            mainItem: Rectangle {
                id: panel

                width: cards.width + 32
                height: cards.height + 32
                radius: tokens.radius
                color: Qt.alpha(tokens.surface, tokens.panelOpacity)
                border.color: tokens.panelBorder
                border.width: 1

                Flow {
                    id: cards

                    x: 16
                    y: 16
                    width: Math.min(repeater.count, tabBox.perRow) * (tabBox.cardWidth + spacing) - spacing
                    spacing: tabBox.spacing

                    Repeater {
                        id: repeater

                        model: tabBox.model

                        Rectangle {
                            id: entry

                            required property int index
                            required property string caption
                            required property var icon
                            required property var windowId
                            required property bool minimized
                            readonly property bool current: entry.index === tabBox.currentIndex

                            width: tabBox.cardWidth
                            height: tabBox.cardHeight
                            radius: Math.max(tokens.radius - 4, 2)
                            color: entry.current ? tokens.selection : "transparent"
                            border.color: entry.current ? tokens.accent : "transparent"
                            border.width: 2

                            Item {
                                id: frame

                                x: 8
                                y: 8
                                width: parent.width - 16
                                height: 136

                                KWin.WindowThumbnail {
                                    anchors.fill: parent
                                    wId: entry.windowId
                                    visible: !entry.minimized
                                }

                                Kirigami.Icon {
                                    anchors.centerIn: parent
                                    width: 64
                                    height: 64
                                    visible: entry.minimized
                                    source: entry.icon
                                }
                            }

                            Row {
                                x: 10
                                y: frame.y + frame.height + 10
                                width: parent.width - 20
                                spacing: 8

                                Kirigami.Icon {
                                    id: smallIcon

                                    width: 20
                                    height: 20
                                    source: entry.icon
                                }

                                Text {
                                    anchors.verticalCenter: smallIcon.verticalCenter
                                    width: parent.width - smallIcon.width - 8
                                    text: entry.caption
                                    textFormat: Text.PlainText
                                    elide: Text.ElideRight
                                    color: tokens.text
                                    font.family: tokens.fontSans
                                    font.pixelSize: tokens.fontSize
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: tabBox.currentIndex = entry.index
                                onClicked: tabBox.model.activate(entry.index)
                            }
                        }
                    }
                }
            }
        }
    }
}
