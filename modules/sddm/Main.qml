import QtQuick
import QtQuick.Controls
import QtQuick.Shapes

Pane {
    id: root
    width: 1280
    height: 800
    padding: 0
    font.family: "Tahoma"
    background: Rectangle {
        color: "#5a7edc"
    }
    property string selectedUser: ""
    property bool manual: userModel.count === 0
    property bool busy: false
    property string message: ""
    property string messageTitle: ""
    property bool failed: false
    property string hoveredKey: ""
    readonly property bool compact: width < 760
    readonly property real u: Math.max(1, Math.min(width / 800, height / 600))
    readonly property bool hasSelection: manual || selectedUser.length > 0
    readonly property bool anyLit: hasSelection || hoveredKey.length > 0
    readonly property int topHeight: Math.round(height * 0.13)
    readonly property int footerHeight: Math.round(height * 0.16)
    readonly property int lineHeight: px(2)
    readonly property string balloonKind: busy ? "" : message.length > 0 ? (failed ? "error" : "info") : hasSelection && keyboard.capsLock && password.activeFocus ? "warning" : ""

    function px(n) {
        return Math.round(n * u);
    }

    function dismissMessage() {
        failed = false;
        message = "";
        messageTitle = "";
    }

    function clearEntry() {
        password.clear();
        username.clear();
        dismissMessage();
    }

    function setHovered(key, hovered) {
        if (hovered)
            hoveredKey = key;
        else if (hoveredKey === key)
            hoveredKey = "";
    }

    function selectUser(name) {
        if (!manual && selectedUser === name) {
            password.forceActiveFocus();
            return;
        }
        selectedUser = name;
        manual = false;
        clearEntry();
        password.forceActiveFocus();
    }

    function selectOther() {
        if (manual) {
            username.forceActiveFocus();
            return;
        }
        selectedUser = "";
        manual = true;
        clearEntry();
        username.forceActiveFocus();
    }

    function tiles() {
        return column.children.filter(child => child.isAccountTile === true);
    }

    function reveal(tile) {
        const bottom = tile.y + tile.height;
        if (bottom > list.contentY + list.height)
            list.contentY = Math.max(0, Math.min(bottom - list.height, list.contentHeight - list.height));
        if (tile.y < list.contentY)
            list.contentY = tile.y;
    }

    function moveFocus(tile, delta) {
        const all = tiles();
        const next = all[all.indexOf(tile) + delta];
        if (next)
            next.forceActiveFocus(Qt.TabFocusReason);
    }

    function signIn() {
        const name = manual ? username.text.trim() : selectedUser;
        if (busy || name.length === 0 || sessionBox.currentIndex < 0)
            return;
        dismissMessage();
        busy = true;
        sddm.login(name, password.text, sessionBox.currentIndex);
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            root.busy = false;
            root.failed = true;
            root.messageTitle = qsTr("Did you forget your password?");
            root.message = root.manual ? qsTr("Please type your user name and password again. Be sure to use the correct uppercase and lowercase letters.") : qsTr("Please type your password again. Be sure to use the correct uppercase and lowercase letters.");
            password.clear();
            password.forceActiveFocus();
        }
        function onLoginSucceeded() {
            password.clear();
        }
        function onInformationMessage(message) {
            root.failed = false;
            root.messageTitle = qsTr("Notice");
            root.message = message;
        }
    }

    Component.onCompleted: {
        if (manual)
            username.forceActiveFocus();
        else if (hasSelection)
            password.forceActiveFocus();
        else if (tiles().length > 0)
            tiles()[0].forceActiveFocus(Qt.OtherFocusReason);
    }

    TapHandler {
        onTapped: root.dismissMessage()
    }

    // Field, light spot and divider
    Item {
        id: field
        y: root.topHeight + root.lineHeight
        width: root.width
        height: root.height - y - root.footerHeight
        clip: true
        Shape {
            ShapePath {
                strokeWidth: -1
                fillGradient: RadialGradient {
                    centerX: root.px(60)
                    centerY: root.px(40)
                    centerRadius: root.px(165)
                    focalX: centerX
                    focalY: centerY
                    GradientStop {
                        position: 0
                        color: "#94b4ef"
                    }
                    GradientStop {
                        position: 0.25
                        color: "#89aaeb"
                    }
                    GradientStop {
                        position: 0.5
                        color: "#789ae6"
                    }
                    GradientStop {
                        position: 0.75
                        color: "#678ae0"
                    }
                    GradientStop {
                        position: 1
                        color: "#5a7edc"
                    }
                }
                startX: 0
                startY: 0
                PathLine {
                    x: root.px(240)
                    y: 0
                }
                PathLine {
                    x: root.px(240)
                    y: root.px(215)
                }
                PathLine {
                    x: 0
                    y: root.px(215)
                }
            }
        }
        Rectangle {
            visible: !root.compact
            x: Math.round(root.width / 2) - root.px(2)
            width: Math.max(1, root.px(1))
            height: parent.height
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: "#5a7edc"
                }
                GradientStop {
                    position: 0.5
                    color: "#91aeee"
                }
                GradientStop {
                    position: 1
                    color: "#5a7edc"
                }
            }
        }
    }

    // Top band
    Rectangle {
        width: root.width
        height: root.topHeight
        color: "#00309c"
    }
    LightLine {
        y: root.topHeight
        width: root.width
        height: root.lineHeight
    }

    // Logo and prompt
    Item {
        id: header
        width: root.compact ? Math.min(root.px(330), root.width - 2 * root.px(24)) : root.px(330)
        height: lockup.height + root.px(20) + prompt.height
        x: root.compact ? Math.round((root.width - width) / 2) : Math.round(root.width / 2) - root.px(22) - width
        y: root.compact ? field.y + root.px(14) : field.y + Math.round((field.height - height) / 2)
        Lockup {
            id: lockup
            u: root.u
            size: root.compact ? 0.75 : 1
            width: implicitWidth
            height: implicitHeight
            x: root.compact ? Math.round((parent.width - width) / 2) : parent.width - width
        }
        Label {
            id: prompt
            objectName: "prompt"
            y: lockup.height + root.px(20)
            width: parent.width
            height: root.px(22)
            text: root.manual ? qsTr("Type your user name and password") : qsTr("To begin, click your user name")
            textFormat: Text.PlainText
            color: "white"
            font.pixelSize: root.px(root.compact ? 14 : 19)
            horizontalAlignment: root.compact ? Text.AlignHCenter : Text.AlignRight
            elide: Text.ElideLeft
        }
    }

    // Accounts
    Flickable {
        id: list
        x: root.compact ? root.px(24) : Math.round(root.width / 2) + root.px(27)
        y: root.compact ? header.y + header.height + root.px(14) : field.y + Math.max(root.px(8), Math.min(Math.round((field.height - root.px(76)) / 2), field.height - column.height - root.px(10)))
        width: root.compact ? root.width - 2 * root.px(24) : Math.min(root.px(355), root.width - x - root.px(20))
        height: Math.max(0, field.y + field.height - y - root.px(10))
        contentWidth: width
        contentHeight: column.height + (column.height > height && root.balloonKind.length > 0 ? root.px(90) : 0)
        clip: contentHeight > height
        interactive: contentHeight > height
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar {
            id: scrollBar
            contentItem: Rectangle {
                implicitWidth: root.px(5)
                radius: width / 2
                color: "#91aeee"
                opacity: scrollBar.size < 1 ? 0.8 : 0
            }
            background: Item {}
        }
        Column {
            id: column
            width: list.width
            spacing: root.px(4)
            Repeater {
                model: userModel
                delegate: AccountTile {
                    id: account
                    objectName: "account-" + name
                    required property string name
                    required property string realName
                    required property var model
                    u: root.u
                    width: column.width
                    title: realName || name
                    picture: model.icon
                    selected: !root.manual && root.selectedUser === name
                    dimmed: root.anyLit && !lit
                    enabled: !root.busy
                    onClicked: root.selectUser(name)
                    onHoveredChanged: root.setHovered(name, hovered)
                    onSelectedChanged: {
                        if (selected) {
                            entry.parent = slot;
                            Qt.callLater(root.reveal, account);
                        }
                    }
                    onActiveFocusChanged: {
                        if (activeFocus)
                            root.reveal(account);
                    }
                    Keys.onUpPressed: root.moveFocus(account, -1)
                    Keys.onDownPressed: root.moveFocus(account, 1)
                    Component.onCompleted: {
                        if (name === userModel.lastUser || userModel.count === 1)
                            root.selectedUser = name;
                        if (selected)
                            entry.parent = slot;
                    }
                }
            }
            AccountTile {
                id: otherUser
                objectName: "other-user"
                u: root.u
                width: column.width
                other: true
                title: qsTr("Other user")
                selected: root.manual
                dimmed: root.anyLit && !lit
                enabled: !root.busy
                onClicked: root.selectOther()
                onHoveredChanged: root.setHovered("#other", hovered)
                onSelectedChanged: {
                    if (selected) {
                        entry.parent = slot;
                        Qt.callLater(root.reveal, otherUser);
                    }
                }
                onActiveFocusChanged: {
                    if (activeFocus)
                        root.reveal(otherUser);
                }
                Keys.onUpPressed: root.moveFocus(otherUser, -1)
                Keys.onDownPressed: root.moveFocus(otherUser, 1)
                Component.onCompleted: {
                    if (selected)
                        entry.parent = slot;
                }
            }
        }
    }

    // Credentials: moved into the selected tile
    Column {
        id: entry
        visible: root.hasSelection
        width: parent ? parent.width : 0
        spacing: root.px(5)
        Column {
            visible: root.manual
            width: parent.width
            spacing: root.px(2)
            Label {
                height: root.px(14)
                text: qsTr("User name")
                color: "white"
                font.pixelSize: root.px(11)
            }
            XpField {
                id: username
                objectName: "username"
                u: root.u
                Accessible.name: qsTr("User name")
                onAccepted: password.forceActiveFocus()
                onTextEdited: root.dismissMessage()
                Keys.onEscapePressed: {
                    clear();
                    root.dismissMessage();
                }
            }
        }
        Column {
            width: parent.width
            spacing: root.px(2)
            Label {
                height: root.px(14)
                text: root.busy ? qsTr("Signing in…") : qsTr("Type your password")
                color: "white"
                font.pixelSize: root.px(11)
            }
            Item {
                width: parent.width
                height: root.px(24)
                XpField {
                    id: password
                    objectName: "password"
                    u: root.u
                    echoMode: TextInput.Password
                    Accessible.name: qsTr("Password")
                    onAccepted: root.signIn()
                    onTextEdited: root.dismissMessage()
                    Keys.onEscapePressed: {
                        clear();
                        root.dismissMessage();
                    }
                }
                ArrowButton {
                    id: submit
                    objectName: "submit"
                    u: root.u
                    x: password.width + root.px(11)
                    Accessible.name: qsTr("Sign in")
                    enabled: !root.busy && (root.manual ? username.text.trim().length > 0 : root.selectedUser.length > 0) && sessionBox.currentIndex >= 0
                    onClicked: root.signIn()
                }
                Balloon {
                    objectName: "balloon"
                    u: root.u
                    z: 10
                    visible: root.balloonKind.length > 0
                    kind: root.balloonKind
                    title: root.balloonKind === "warning" ? qsTr("Caps Lock is on") : root.messageTitle
                    text: root.balloonKind === "warning" ? qsTr("Having Caps Lock on may cause you to enter your password incorrectly. Press Caps Lock to turn it off.") : root.message
                    x: submit.x + Math.round(submit.width / 2) - tipX
                    y: parent.height + root.px(6)
                }
            }
        }
    }

    // Footer
    OrangeLine {
        y: root.height - root.footerHeight
        width: root.width
        height: root.lineHeight
    }
    Rectangle {
        y: root.height - root.footerHeight + root.lineHeight
        width: root.width
        height: root.footerHeight - root.lineHeight
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop {
                position: 0
                color: "#3934ad"
            }
            GradientStop {
                position: 1
                color: "#00309c"
            }
        }
    }
    Button {
        id: turnOff
        objectName: "turn-off"
        visible: sddm.canPowerOff || sddm.canReboot || sddm.canSuspend
        enabled: !root.busy
        x: root.px(24)
        y: root.height - root.footerHeight + root.px(22)
        padding: 0
        hoverEnabled: true
        Accessible.name: qsTr("Turn off computer")
        Keys.onReturnPressed: click()
        Keys.onEnterPressed: click()
        onClicked: powerDialog.open()
        contentItem: Row {
            spacing: root.px(7)
            Image {
                width: root.px(24)
                height: root.px(24)
                sourceSize: Qt.size(width, height)
                source: "assets/shutdown.svg"
            }
            Label {
                height: root.px(24)
                text: qsTr("Turn off computer")
                color: "white"
                font.pixelSize: root.px(19)
                font.underline: turnOff.hovered
                verticalAlignment: Text.AlignVCenter
            }
        }
        background: Rectangle {
            anchors.fill: parent
            anchors.margins: -root.px(3)
            radius: root.px(3)
            color: "transparent"
            border.width: turnOff.visualFocus ? 1 : 0
            border.color: "#ffdc8a"
        }
    }
    Column {
        x: root.width - width - root.px(24)
        y: root.height - root.footerHeight + root.px(24)
        spacing: root.px(3)
        FooterCombo {
            id: sessionBox
            objectName: "session"
            u: root.u
            visible: sessionModel.count > 1
            enabled: !root.busy
            caption: qsTr("Desktop:")
            model: sessionModel
            textRole: "name"
            currentIndex: sessionModel.lastIndex
            Accessible.name: qsTr("Desktop session")
        }
        FooterCombo {
            objectName: "keyboard"
            u: root.u
            visible: keyboard.layouts.length > 1
            enabled: !root.busy
            caption: qsTr("Keyboard:")
            model: keyboard.layouts
            textRole: "longName"
            currentIndex: keyboard.currentLayout
            onActivated: index => keyboard.currentLayout = index
            Accessible.name: qsTr("Keyboard layout")
        }
    }

    PowerDialog {
        id: powerDialog
        objectName: "powerDialog"
        u: root.u
        canSuspend: sddm.canSuspend
        canPowerOff: sddm.canPowerOff
        canReboot: sddm.canReboot
        onSuspend: {
            password.clear();
            sddm.suspend();
        }
        onPowerOff: {
            password.clear();
            sddm.powerOff();
        }
        onReboot: {
            password.clear();
            sddm.reboot();
        }
    }
}
