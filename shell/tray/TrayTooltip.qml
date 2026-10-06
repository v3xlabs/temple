import QtQuick
import Quickshell
import "../theme"
import "../frame"

// The hover tip of a tray icon.
PopupWindow {
    id: tip

    required property Item trigger
    property string text
    property bool hovered: false
    property bool shown: false

    readonly property int gap: 4

    anchor.item: trigger
    anchor.edges: TrayStyle.opensDown ? Edges.Bottom : Edges.Top
    anchor.gravity: TrayStyle.opensDown ? Edges.Bottom : Edges.Top
    anchor.adjustment: PopupAdjustment.Slide
    implicitWidth: label.implicitWidth + TrayStyle.tip.paddingX * 2
    implicitHeight: label.implicitHeight + TrayStyle.tip.paddingY * 2 + gap
    color: "transparent"
    visible: shown && hovered && text !== ""

    onHoveredChanged: {
        shown = false;
        if (hovered)
            delay.restart();
        else
            delay.stop();
    }

    Timer {
        id: delay

        interval: 500
        onTriggered: tip.shown = true
    }

    Item {
        anchors.fill: parent
        anchors.topMargin: TrayStyle.opensDown ? tip.gap : 0
        anchors.bottomMargin: TrayStyle.opensDown ? 0 : tip.gap

        Frame {
            anchors.fill: parent
            kind: TrayStyle.tip.frame
            double: false
            color: TrayStyle.tip.color
            border: TrayStyle.tip.border
            radius: TrayStyle.tip.radius
        }

        Text {
            id: label

            anchors.centerIn: parent
            text: tip.text
            color: TrayStyle.text
            font.family: TrayStyle.font
            font.pixelSize: Theme.textSize(-1)
        }
    }
}
