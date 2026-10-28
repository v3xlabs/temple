import QtQuick
import QtQuick.Controls

// XP's "Turn off computer" dialog. Offers only the actions the system allows
// and dims the screen behind it.
Popup {
    id: dialog
    property real u: 1
    property bool canSuspend: false
    property bool canPowerOff: false
    property bool canReboot: false
    signal suspend
    signal powerOff
    signal reboot

    function px(n) {
        return Math.round(n * u);
    }

    function focusFirst() {
        for (const item of [standBy, turnOff, restart, cancel]) {
            if (item.visible) {
                item.forceActiveFocus(Qt.TabFocusReason);
                return;
            }
        }
    }

    function step(delta) {
        const items = [standBy, turnOff, restart, cancel].filter(item => item.visible);
        const at = items.findIndex(item => item.activeFocus);
        items[(Math.max(at, 0) + delta + items.length) % items.length].forceActiveFocus(Qt.TabFocusReason);
    }

    parent: Overlay.overlay
    anchors.centerIn: parent
    width: px(313)
    height: px(200)
    padding: 0
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape
    font.family: "Tahoma"
    onOpened: focusFirst()
    Overlay.modal: Rectangle {
        color: "#b8636363"
    }
    background: Rectangle {
        radius: dialog.px(8)
        color: "#003399"
    }
    contentItem: Item {
        Keys.onPressed: event => {
            const key = event.key;
            if (key === Qt.Key_Left || key === Qt.Key_Up)
                dialog.step(-1);
            else if (key === Qt.Key_Right || key === Qt.Key_Down)
                dialog.step(1);
            else if (key === Qt.Key_S && standBy.visible)
                standBy.click();
            else if (key === Qt.Key_U && turnOff.visible)
                turnOff.click();
            else if (key === Qt.Key_R && restart.visible)
                restart.click();
            else
                return;
            event.accepted = true;
        }
        Label {
            x: dialog.px(12)
            height: dialog.px(44)
            text: qsTr("Turn off computer")
            color: "white"
            font.pixelSize: dialog.px(18)
            verticalAlignment: Text.AlignVCenter
            Accessible.role: Accessible.Heading
        }
        Image {
            x: parent.width - width - dialog.px(10)
            y: dialog.px(4)
            width: dialog.px(34)
            height: dialog.px(34)
            sourceSize: Qt.size(width, height)
            source: "logo.svg"
            fillMode: Image.PreserveAspectFit
        }
        LightLine {
            y: dialog.px(44)
            width: parent.width
            height: dialog.px(2)
        }
        Rectangle {
            y: dialog.px(46)
            width: parent.width
            height: dialog.px(110)
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop {
                    position: 0
                    color: "#5a7dde"
                }
                GradientStop {
                    position: 0.55
                    color: "#93b2f4"
                }
                GradientStop {
                    position: 1
                    color: "#6b8de5"
                }
            }
        }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            y: dialog.px(76)
            spacing: dialog.px(16)
            PowerAction {
                id: standBy
                objectName: "power-standby"
                u: dialog.u
                visible: dialog.canSuspend
                art: "assets/standby.svg"
                caption: qsTr("Stand By")
                mnemonic: 0
                onClicked: {
                    dialog.close();
                    dialog.suspend();
                }
            }
            PowerAction {
                id: turnOff
                objectName: "power-off"
                u: dialog.u
                visible: dialog.canPowerOff
                art: "assets/shutdown.svg"
                caption: qsTr("Turn Off")
                mnemonic: 1
                onClicked: {
                    dialog.close();
                    dialog.powerOff();
                }
            }
            PowerAction {
                id: restart
                objectName: "power-restart"
                u: dialog.u
                visible: dialog.canReboot
                art: "assets/restart.svg"
                caption: qsTr("Restart")
                mnemonic: 0
                onClicked: {
                    dialog.close();
                    dialog.reboot();
                }
            }
        }
        LunaButton {
            id: cancel
            objectName: "power-cancel"
            u: dialog.u
            x: parent.width - width - dialog.px(11)
            y: dialog.px(169)
            width: dialog.px(57)
            text: qsTr("Cancel")
            onClicked: dialog.close()
        }
    }
}
