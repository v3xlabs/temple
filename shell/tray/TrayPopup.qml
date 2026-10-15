pragma ComponentBehavior: Bound
import QtQuick
import Quickshell

// A flyout attached to a tray icon. It opens away from the bar and right-aligns with the icon.
PopupWindow {
    id: popup

    required property Item trigger
    property int panelWidth: 260
    property int padding: TrayStyle.popup.padding
    default property alias content: body.data

    // Distance between the bar edge and the flyout.
    readonly property int gap: 4
    property double closedAt: 0

    function toggle() {
        if (visible) {
            visible = false;
            return;
        }
        // A click on the tray icon first dismisses the flyout through the grab; it must not reopen it.
        if (Date.now() - closedAt < 250)
            return;
        const position = trigger.mapToItem(null, 0, 0);
        anchor.rect.x = 0;
        anchor.rect.y = -position.y;
        anchor.rect.width = trigger.width;
        anchor.rect.height = trigger.Window.height;
        visible = true;
        keys.forceActiveFocus();
    }

    anchor.item: trigger
    anchor.edges: TrayStyle.opensDown ? Edges.Bottom | Edges.Right : Edges.Top | Edges.Right
    anchor.gravity: TrayStyle.opensDown ? Edges.Bottom | Edges.Left : Edges.Top | Edges.Left
    anchor.adjustment: PopupAdjustment.Slide
    implicitWidth: panelWidth
    implicitHeight: body.implicitHeight + padding * 2 + gap
    color: "transparent"
    grabFocus: true
    onVisibleChanged: {
        if (!visible)
            closedAt = Date.now();
    }

    Item {
        id: keys

        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: popup.visible = false

        Item {
            id: frame

            anchors.fill: parent
            anchors.topMargin: TrayStyle.opensDown ? popup.gap : 0
            anchors.bottomMargin: TrayStyle.opensDown ? 0 : popup.gap

            TrayFrame {
                anchors.fill: parent
            }

            Column {
                id: body

                x: popup.padding
                y: popup.padding
                width: frame.width - popup.padding * 2
                spacing: 4
            }
        }
    }
}
