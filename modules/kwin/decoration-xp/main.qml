import QtQuick
import org.kde.kwin.decoration

// The Windows XP Luna Blue window frame, assembled from the luna.msstyles
// bitmaps next to this file the way XP's theme engine lays them out
// (Window.* in NORMALBLUE_INI): a 9-slice caption, stretched side and bottom
// frames, and 21px buttons 24px apart from the top right.
Decoration {
    id: root

    readonly property bool active: decoration.client.active
    readonly property bool maximized: decoration.client.maximized
    readonly property string look: active ? "active" : "inactive"
    // The caption bitmap includes the top border; a maximized window shows
    // only the 25px caption bar below it.
    readonly property int captionHeight: 29
    readonly property int hiddenTop: maximized ? 4 : 0
    // XP's sizing frame is 4px on every side but the top.
    readonly property int sideWidth: 4
    readonly property int bottomHeight: 4

    alpha: true

    Component.onCompleted: {
        borders.setBorders(sideWidth);
        borders.setTitle(captionHeight);
        maximizedBorders.setTitle(captionHeight - 4);
        // The frame is thin; the grab area reaches past it.
        extendedBorders.setAllBorders(4);
    }

    BorderImage {
        id: caption

        x: 0
        y: -root.hiddenTop
        width: parent.width
        height: root.captionHeight
        source: (root.maximized ? "maximized-" : "caption-") + root.look + ".png"
        border.left: 28
        border.right: 35
        border.top: 9
        border.bottom: 17
        horizontalTileMode: BorderImage.Stretch
        verticalTileMode: BorderImage.Stretch
        smooth: false
    }

    Image {
        visible: !root.maximized
        x: 0
        y: root.captionHeight
        width: root.sideWidth
        height: parent.height - root.captionHeight - root.bottomHeight
        source: "left-" + root.look + ".png"
        fillMode: Image.Stretch
        smooth: false
    }

    Image {
        visible: !root.maximized
        x: parent.width - root.sideWidth
        y: root.captionHeight
        width: root.sideWidth
        height: parent.height - root.captionHeight - root.bottomHeight
        source: "right-" + root.look + ".png"
        fillMode: Image.Stretch
        smooth: false
    }

    BorderImage {
        visible: !root.maximized
        x: 0
        y: parent.height - root.bottomHeight
        width: parent.width
        height: root.bottomHeight
        source: "bottom-" + root.look + ".png"
        border.left: 5
        border.right: 5
        border.top: 2
        border.bottom: 2
        smooth: false
    }

    Item {
        id: titleBar

        x: root.sideWidth
        y: 0
        width: parent.width - root.sideWidth * 2
        height: root.captionHeight - root.hiddenTop

        // KWin takes the drag area from the children's bounds.
        Item {
            anchors.fill: parent
        }

        MenuButton {
            id: icon

            x: 2
            y: 7 - root.hiddenTop
            width: 16
            height: 16
        }

        Text {
            id: title

            x: icon.x + icon.width + 4
            y: 4 - root.hiddenTop
            width: buttons.x - x - 4
            height: 25
            verticalAlignment: Text.AlignVCenter
            text: decoration.client.caption
            textFormat: Text.PlainText
            elide: Text.ElideRight
            // XP draws captions in Trebuchet MS Bold with a one pixel shadow.
            // Trebuchet is not free to ship; Tahoma Bold, XP's other UI face, stands in.
            font.family: "Tahoma"
            font.pixelSize: 13
            font.bold: true
            color: root.active ? "#ffffff" : "#d8e4f8"
            style: root.active ? Text.Raised : Text.Normal
            styleColor: "#0a1883"
            renderType: Text.NativeRendering
        }

        Row {
            id: buttons

            x: parent.width - width
            y: 5 - root.hiddenTop
            spacing: 3

            CaptionButton {
                buttonType: DecorationOptions.DecorationButtonMinimize
                glyph: "minimize"
            }
            CaptionButton {
                buttonType: DecorationOptions.DecorationButtonMaximizeRestore
                glyph: decoration.client.maximized ? "restore" : "maximize"
            }
            CaptionButton {
                buttonType: DecorationOptions.DecorationButtonClose
                face: "close"
                glyph: "close"
            }
        }

        Component.onCompleted: decoration.installTitleItem(titleBar)
    }

    component CaptionButton: DecorationButton {
        id: button

        property string face: "button"
        property string glyph
        // normal, hot, pressed, disabled; four more for an inactive window.
        readonly property int frame: (root.active ? 0 : 4) + (!enabled ? 3 : pressed ? 2 : hovered ? 1 : 0)

        width: 21
        height: 21

        Image {
            anchors.fill: parent
            source: button.face + "-" + button.frame + ".png"
            smooth: false
        }

        Image {
            x: 4
            y: 4
            source: button.glyph + "-glyph-" + button.frame + ".png"
            smooth: false
        }
    }
}
