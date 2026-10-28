import QtQuick
import QtTest
import "../../modules/sddm" as Theme

// Loads the real Main.qml against a mocked SDDM and drives it like a user.
Item {
    width: 1280
    height: 800

    ListModel {
        id: userModel
        property string lastUser: ""
    }
    ListModel {
        id: sessionModel
        property int lastIndex: 0
    }
    QtObject {
        id: keyboard
        property bool capsLock: false
        property var layouts: []
        property int currentLayout: 0
    }
    QtObject {
        id: sddm
        property bool canSuspend: true
        property bool canPowerOff: true
        property bool canReboot: true
        property int logins: 0
        property string name: ""
        property string password: ""
        property int session: -1
        property var powerCalls: []
        signal loginFailed
        signal loginSucceeded
        signal informationMessage(string message)
        function login(user, secret, index) {
            logins++;
            name = user;
            password = secret;
            session = index;
        }
        function suspend() {
            powerCalls = powerCalls.concat("suspend");
        }
        function powerOff() {
            powerCalls = powerCalls.concat("powerOff");
        }
        function reboot() {
            powerCalls = powerCalls.concat("reboot");
        }
    }
    Loader {
        id: loader
        anchors.fill: parent
        active: false
        sourceComponent: Theme.Main {}
    }

    TestCase {
        name: "TempleSignin"
        when: windowShown

        readonly property var two: ["temple", "guest"]
        readonly property var three: ["Temple", "Plasma", "GNOME"]

        function start(users, last, sessions = ["Temple", "Plasma"], lastSession = 0) {
            loader.active = false;
            userModel.clear();
            for (const user of users)
                userModel.append({
                    name: user,
                    realName: user.charAt(0).toUpperCase() + user.slice(1),
                    icon: ""
                });
            userModel.lastUser = last;
            sessionModel.clear();
            for (const session of sessions)
                sessionModel.append({
                    name: session
                });
            sessionModel.lastIndex = lastSession;
            sddm.canSuspend = true;
            sddm.canPowerOff = true;
            sddm.canReboot = true;
            sddm.logins = 0;
            sddm.name = "";
            sddm.password = "";
            sddm.session = -1;
            sddm.powerCalls = [];
            keyboard.capsLock = false;
            loader.active = true;
            verify(loader.item !== null);
            wait(0);
        }
        function child(name) {
            const found = findChild(loader.item, name);
            verify(found !== null, "missing " + name);
            return found;
        }
        function type(text) {
            for (const letter of text)
                keyClick(letter);
        }
        function openPowerDialog() {
            mouseClick(child("turn-off"));
            const dialog = child("powerDialog");
            tryVerify(() => dialog.opened);
            return dialog;
        }

        function test_several_users_without_last_user_waits_for_a_click() {
            start(two, "");
            verify(!loader.item.manual);
            compare(loader.item.selectedUser, "");
            verify(!child("password").visible);
            verify(!child("username").visible);
            verify(child("prompt").text.length > 0);

            mouseClick(child("account-guest"));
            compare(loader.item.selectedUser, "guest");
            verify(child("password").visible);
            verify(child("password").activeFocus);
            verify(!child("username").visible);
        }

        function test_prompt_stays_while_an_account_is_selected() {
            start(two, "temple");
            verify(child("password").visible);
            verify(child("prompt").text.length > 0);
        }

        function test_last_user_is_selected_with_password_field() {
            start(two, "guest");
            compare(loader.item.selectedUser, "guest");
            verify(child("password").visible);
            verify(child("password").activeFocus);
        }

        function test_single_user_is_selected_automatically() {
            start(["temple"], "");
            compare(loader.item.selectedUser, "temple");
            verify(!loader.item.manual);
            verify(child("password").visible);
            verify(child("password").activeFocus);
        }

        function test_no_users_asks_for_a_name() {
            start([], "");
            verify(loader.item.manual);
            verify(child("username").visible);
            verify(child("password").visible);
            verify(child("username").activeFocus);
            type("root");
            keyClick(Qt.Key_Return);
            verify(child("password").activeFocus);
        }

        function test_selected_account_signs_in_with_typed_password() {
            start(two, "temple");
            type("secret");
            keyClick(Qt.Key_Return);
            compare(sddm.logins, 1);
            compare(sddm.name, "temple");
            compare(sddm.password, "secret");
            compare(sddm.session, 0);
        }

        function test_wrong_password_clears_field_and_shows_balloon() {
            start(two, "temple");
            const password = child("password");
            const balloon = child("balloon");
            verify(!balloon.visible);
            type("wrong");
            keyClick(Qt.Key_Return);
            sddm.loginFailed();
            compare(password.text, "");
            verify(balloon.visible);
            verify(password.activeFocus);
            verify(!loader.item.busy);

            keyClick("a");
            verify(!balloon.visible);
            keyClick(Qt.Key_Return);
            compare(sddm.logins, 2);
        }

        function test_switching_account_clears_password() {
            start(two, "temple");
            type("old");
            compare(child("password").text, "old");
            mouseClick(child("account-guest"));
            compare(loader.item.selectedUser, "guest");
            compare(child("password").text, "");
            verify(child("password").activeFocus);
        }

        function test_duplicate_submit_sends_one_login() {
            start(two, "temple");
            type("secret");
            keyClick(Qt.Key_Return);
            keyClick(Qt.Key_Return);
            mouseClick(child("submit"));
            compare(sddm.logins, 1);
            verify(loader.item.busy);
        }

        function test_other_user_signs_in_with_typed_name() {
            start(two, "temple");
            mouseClick(child("other-user"));
            verify(loader.item.manual);
            verify(child("username").visible);
            verify(child("username").activeFocus);
            verify(child("password").visible);
            type("ghost");
            keyClick(Qt.Key_Return);
            type("boo");
            keyClick(Qt.Key_Return);
            compare(sddm.logins, 1);
            compare(sddm.name, "ghost");
            compare(sddm.password, "boo");
        }

        function test_non_default_session_is_sent_to_login() {
            start(two, "temple", three);
            const box = child("session");
            verify(box.visible);
            compare(box.currentIndex, 0);
            mouseClick(box);
            tryVerify(() => box.popup.opened);
            tryVerify(() => box.popup.contentItem.itemAtIndex(2) !== null);
            mouseClick(box.popup.contentItem.itemAtIndex(2));
            compare(box.currentIndex, 2);
            child("password").forceActiveFocus();
            type("secret");
            keyClick(Qt.Key_Return);
            compare(sddm.session, 2);
        }

        function test_session_is_reachable_by_keyboard() {
            start(two, "temple", three);
            const box = child("session");
            box.forceActiveFocus(Qt.TabFocusReason);
            keyClick(Qt.Key_Down);
            compare(box.currentIndex, 1);
            child("password").forceActiveFocus();
            type("secret");
            keyClick(Qt.Key_Return);
            compare(sddm.session, 1);
        }

        function test_session_starts_on_last_used() {
            start(two, "temple", three, 1);
            compare(child("session").currentIndex, 1);
            type("secret");
            keyClick(Qt.Key_Return);
            compare(sddm.session, 1);
        }

        function test_session_control_hidden_with_one_session() {
            start(two, "temple", ["Temple"]);
            verify(!child("session").visible);
        }

        function test_power_dialog_data() {
            return [
                {
                    tag: "all",
                    suspend: true,
                    off: true,
                    reboot: true
                },
                {
                    tag: "no-suspend",
                    suspend: false,
                    off: true,
                    reboot: true
                },
                {
                    tag: "no-reboot",
                    suspend: true,
                    off: true,
                    reboot: false
                },
                {
                    tag: "only-restart",
                    suspend: false,
                    off: false,
                    reboot: true
                }
            ];
        }
        function test_power_dialog(data) {
            start(two, "temple");
            sddm.canSuspend = data.suspend;
            sddm.canPowerOff = data.off;
            sddm.canReboot = data.reboot;
            const dialog = openPowerDialog();
            compare(child("power-standby").visible, data.suspend);
            compare(child("power-off").visible, data.off);
            compare(child("power-restart").visible, data.reboot);
            verify(child("power-cancel").visible);
            keyClick(Qt.Key_Escape);
            tryVerify(() => !dialog.opened);
            compare(sddm.powerCalls.length, 0);
        }

        function test_power_dialog_turn_off_with_enter() {
            start(two, "temple");
            const dialog = openPowerDialog();
            verify(child("power-standby").activeFocus);
            keyClick(Qt.Key_Right);
            verify(child("power-off").activeFocus);
            keyClick(Qt.Key_Return);
            tryVerify(() => !dialog.opened);
            compare(sddm.powerCalls, ["powerOff"]);
        }

        function test_power_dialog_stand_by_and_restart() {
            start(two, "temple");
            openPowerDialog();
            mouseClick(child("power-standby"));
            compare(sddm.powerCalls, ["suspend"]);
            tryVerify(() => !child("powerDialog").opened);
            openPowerDialog();
            mouseClick(child("power-restart"));
            compare(sddm.powerCalls, ["suspend", "reboot"]);
        }

        function test_power_button_hidden_when_nothing_is_allowed() {
            start(two, "temple");
            sddm.canSuspend = false;
            sddm.canPowerOff = false;
            sddm.canReboot = false;
            verify(!child("turn-off").visible);
        }
    }
}
