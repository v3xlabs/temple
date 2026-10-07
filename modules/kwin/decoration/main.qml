import QtQuick
import org.kde.kwin.decoration

// Temple's window frame: a flat title bar with round buttons inside a border.
// The NixOS module builds one package per theme around this file, with that
// theme's values in Tokens.qml.
Decoration {
    id: root

    readonly property int titleHeight: 26
    readonly property int buttonSize: 16
    readonly property bool active: decoration.client.active
    readonly property bool maximized: decoration.client.maximized
    readonly property int frameWidth: maximized ? 0 : tokens.border
    readonly property int innerRadius: maximized ? 0 : Math.max(tokens.rounding - tokens.border, 0)

    Tokens {
        id: tokens
    }

    Component.onCompleted: {
        borders.setBorders(tokens.border);
        borders.setTitle(tokens.border + titleHeight);
        maximizedBorders.setTitle(titleHeight);
        // Thin borders stay easy to grab.
        extendedBorders.setAllBorders(Math.max(8 - tokens.border, 0));
    }

    Rectangle {
        anchors.fill: parent
        radius: root.maximized ? 0 : tokens.rounding
        gradient: Gradient {
            orientation: Gradient.Horizontal

            GradientStop {
                position: 0
                color: root.active ? tokens.activeFrom : tokens.inactiveFrom
            }
            GradientStop {
                position: 1
                color: root.active ? tokens.activeTo : tokens.inactiveTo
            }
        }
    }

    Rectangle {
        id: titleBar

        x: root.frameWidth
        y: root.frameWidth
        width: parent.width - root.frameWidth * 2
        height: root.titleHeight
        color: tokens.titleColor
        topLeftRadius: root.innerRadius
        topRightRadius: root.innerRadius

        // KWin takes the title bar's drag and double-click area from the
        // children's bounds, so one child spans the whole bar.
        Item {
            anchors.fill: parent
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - (buttons.width + 12) * 2
            horizontalAlignment: Text.AlignHCenter
            text: decoration.client.caption
            textFormat: Text.PlainText
            elide: Text.ElideRight
            color: tokens.titleText
            font.family: tokens.fontSans
            font.pixelSize: tokens.fontSize
        }

        Row {
            id: buttons

            anchors.verticalCenter: parent.verticalCenter
            x: tokens.buttonsLeft ? 6 : parent.width - width - 6
            spacing: 6
            // The first button sits nearest the edge the buttons align to.
            layoutDirection: tokens.buttonsLeft ? Qt.LeftToRight : Qt.RightToLeft

            Repeater {
                model: tokens.buttonsLeft ? [DecorationOptions.DecorationButtonClose, DecorationOptions.DecorationButtonMinimize, DecorationOptions.DecorationButtonMaximizeRestore] : [DecorationOptions.DecorationButtonClose, DecorationOptions.DecorationButtonMaximizeRestore, DecorationOptions.DecorationButtonMinimize]

                DecorationButton {
                    id: button

                    required property int modelData
                    readonly property bool close: modelData === DecorationOptions.DecorationButtonClose

                    buttonType: modelData
                    width: root.buttonSize
                    height: root.buttonSize

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        opacity: button.pressed ? 0.7 : button.hovered ? 0.85 : 1
                        color: button.close ? tokens.close : button.modelData === DecorationOptions.DecorationButtonMinimize ? tokens.minimize : tokens.maximize
                    }

                    Text {
                        anchors.centerIn: parent
                        text: button.close ? "×" : button.modelData === DecorationOptions.DecorationButtonMinimize ? "–" : "□"
                        color: button.close ? tokens.closeText : tokens.buttonText
                        font.pixelSize: 12
                    }
                }
            }
        }

        Component.onCompleted: decoration.installTitleItem(titleBar)
    }
}
