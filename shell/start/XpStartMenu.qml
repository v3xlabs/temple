pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "../theme"
import "../apps"
import "../session"
import "../windows"

// The Luna Blue Start panel, assembled from the luna.msstyles bitmaps in
// /etc/temple/luna/startpanel the way XP lays out StartPanel.* in
// NORMALBLUE_INI: each pane's default size, sizing margins and content margins
// come from there.
PanelWindow {
    id: root

    signal launcherRequested
    signal themesRequested

    property bool open: false
    property bool programsOpen: false
    // Window y of the All Programs row's bottom edge; the flyout grows upward from there.
    property real programsBottom: 0
    // The selected row of the two columns, from the mouse or the arrow keys.
    property Item current: null

    readonly property string home: Quickshell.env("HOME")
    readonly property string bitmaps: "file:///etc/temple/luna/startpanel/"

    function toggle(target: ShellScreen) {
        if (open) {
            close();
            return;
        }
        screen = target;
        programsOpen = false;
        current = null;
        open = true;
        focusScope.forceActiveFocus();
    }

    function close() {
        programsOpen = false;
        current = null;
        open = false;
    }

    // The overlay covers one screen; a window focused from elsewhere closes it.
    Connections {
        target: Windows
        function onActiveChanged() {
            if (root.open && Windows.active !== null)
                root.close();
        }
    }

    onCurrentChanged: {
        if (current !== null && current !== allPrograms)
            programsOpen = false;
    }

    function openFolder(path: string) {
        close();
        Quickshell.execDetached(["xdg-open", path]);
    }

    function openPrograms(fromKeyboard: bool) {
        programsBottom = allPrograms.mapToItem(root.contentItem, 0, allPrograms.height).y;
        programList.currentIndex = fromKeyboard ? 0 : -1;
        programList.positionViewAtBeginning();
        programsOpen = true;
    }

    function confirmSession(mode: string) {
        const target = screen;
        close();
        sessionDialog.show(target, mode);
    }

    // Used by the launcher's session commands.
    function confirmOn(target: ShellScreen, action: string) {
        close();
        sessionDialog.show(target, action === "logout" ? "logoff" : "shutdown");
    }

    function rows(column: Item): var {
        return Array.from(column.children).filter(child => child.navigable === true && child.visible);
    }

    // Up and Down move inside a column and wrap; Left and Right change column;
    // Right on All Programs opens the flyout, which then takes Up, Down and Left.
    function navigate(key: int): bool {
        const enter = key === Qt.Key_Return || key === Qt.Key_Enter;
        if (programsOpen && programList.currentIndex >= 0) {
            if (key === Qt.Key_Up)
                programList.decrementCurrentIndex();
            else if (key === Qt.Key_Down)
                programList.incrementCurrentIndex();
            else if (key === Qt.Key_Left)
                programsOpen = false;
            else if (enter)
                programList.currentItem.launch();
            else
                return false;
            return true;
        }
        const columns = [rows(leftColumn).concat([allPrograms]), rows(rightColumn)];
        const side = columns[1].includes(current) ? 1 : 0;
        const column = columns[side];
        const index = column.indexOf(current);
        if (key === Qt.Key_Down)
            current = column[(index + 1) % column.length];
        else if (key === Qt.Key_Up)
            current = column[index <= 0 ? column.length - 1 : index - 1];
        else if (key === Qt.Key_Right && current === allPrograms)
            openPrograms(true);
        else if (key === Qt.Key_Right && side === 0)
            current = columns[1][Math.min(Math.max(index, 0), columns[1].length - 1)];
        else if (key === Qt.Key_Left && side === 1)
            current = columns[0][Math.min(index, columns[0].length - 1)];
        else if (enter && current !== null)
            current.activated();
        else
            return false;
        return true;
    }

    visible: open
    WlrLayershell.namespace: "temple-startmenu"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Normal

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"

    // XP fills the selected row with the system highlight colour; luna.msstyles
    // has no bitmap for it.
    component Highlight: Rectangle {
        color: "#316ac5"
    }

    component MenuRow: Item {
        id: row

        property string label
        property string icon
        property int iconSize: 32
        property bool bold: false
        property color textColor
        readonly property bool navigable: true
        readonly property bool highlighted: root.current === row

        signal activated

        Layout.fillWidth: true
        implicitHeight: row.iconSize + 8

        Highlight {
            anchors.fill: parent
            visible: row.highlighted
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 6
            anchors.rightMargin: 6
            spacing: 6

            IconImage {
                implicitSize: row.iconSize
                source: Apps.iconSource(row.icon)
            }

            Text {
                Layout.fillWidth: true
                text: row.label
                elide: Text.ElideRight
                color: row.highlighted ? "#ffffff" : row.textColor
                font.family: Theme.fontSans
                font.pixelSize: Theme.fontSize
                font.bold: row.bold
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: root.current = row
            onExited: {
                if (root.current === row)
                    root.current = null;
            }
            onClicked: row.activated()
        }
    }

    // ProgListSeparator and PlacesListSeparator: TrueSize bitmaps.
    component Separator: Image {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 3
        Layout.bottomMargin: 3
        smooth: false
    }

    // A LogoffButtons icon: the normal strip, or the hot strip under the mouse.
    component FooterButton: Item {
        id: footerButton

        property string label
        property string bitmap

        signal activated

        implicitWidth: footerRow.implicitWidth + 8
        implicitHeight: 30

        Row {
            id: footerRow

            anchors.centerIn: parent
            spacing: 5

            Image {
                anchors.verticalCenter: parent.verticalCenter
                source: root.bitmaps + footerButton.bitmap + (footerArea.containsMouse ? "-hot.png" : ".png")
                smooth: false
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: footerButton.label
                color: "#ffffff"
                font.family: Theme.fontSans
                font.pixelSize: Theme.fontSize
            }
        }

        MouseArea {
            id: footerArea

            anchors.fill: parent
            hoverEnabled: true
            onClicked: footerButton.activated()
        }
    }

    XpSessionDialog {
        id: sessionDialog
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    FocusScope {
        id: focusScope

        anchors.fill: parent
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                if (root.programsOpen)
                    root.programsOpen = false;
                else
                    root.close();
            } else {
                event.accepted = root.navigate(event.key);
            }
        }
    }

    Item {
        id: menu

        // StartPanel.*.DefaultPaneSize: a 380px panel, 64px user pane, two
        // 190px columns at least 336px tall and a 40px log-off pane.
        readonly property int headerHeight: 64
        readonly property int columnWidth: 190
        readonly property int footerHeight: 40
        readonly property int moreProgramsHeight: 30

        x: 0
        y: parent.height - height
        width: columnWidth * 2
        height: headerHeight + body.height + footerHeight

        MouseArea {
            anchors.fill: parent
        }

        BorderImage {
            id: header

            width: parent.width
            height: menu.headerHeight
            source: root.bitmaps + "userpane.png"
            border.left: 59
            border.right: 60
            border.top: 62
            border.bottom: 0
            smooth: false

            // StartPanel.UserPicture: the tile is stretched around a 48px picture
            // inside its content margins (8, 6, 8, 6).
            BorderImage {
                id: picture

                x: 1
                y: 2
                width: 62
                height: 62
                source: root.bitmaps + "usertile.png"
                border.left: 6
                border.right: 10
                border.top: 6
                border.bottom: 10
                smooth: false

                Rectangle {
                    x: 8
                    y: 8
                    width: 48
                    height: 48
                    gradient: Gradient {
                        GradientStop {
                            position: 0
                            color: "#a9cdf7"
                        }
                        GradientStop {
                            position: 1
                            color: "#4f86dc"
                        }
                    }

                    IconImage {
                        anchors.centerIn: parent
                        implicitSize: 36
                        source: Apps.iconSource("user-identity")
                    }
                }
            }

            // StartPanel.UserPane: 14pt white text with a continuous 2px shadow.
            Item {
                anchors.left: picture.right
                anchors.leftMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: userLabel.implicitWidth + 2
                implicitHeight: userLabel.implicitHeight + 2

                Text {
                    x: 2
                    y: 2
                    text: userLabel.text
                    font: userLabel.font
                    color: "#09428b"
                }

                Text {
                    id: userLabel

                    text: Session.user
                    color: "#ffffff"
                    font.family: Theme.fontSans
                    font.pixelSize: 19
                    font.bold: true
                }
            }
        }

        Item {
            id: body

            y: menu.headerHeight
            width: parent.width
            // Content margins (top 9, bottom 5) of both lists come on top of their rows.
            height: Math.max(336, leftColumn.implicitHeight + 14 + menu.moreProgramsHeight, rightColumn.implicitHeight + 14)

            // StartPanel.ProgList
            BorderImage {
                id: left

                width: menu.columnWidth
                height: parent.height - menu.moreProgramsHeight
                source: root.bitmaps + "proglist.png"
                border.left: 2
                border.right: 153
                border.top: 3
                border.bottom: 0
                smooth: false

                ColumnLayout {
                    id: leftColumn

                    anchors.fill: parent
                    anchors.leftMargin: 6
                    anchors.rightMargin: 4
                    anchors.topMargin: 9
                    anchors.bottomMargin: 5
                    spacing: 0

                    Repeater {
                        model: Apps.commands

                        MenuRow {
                            required property var modelData

                            label: modelData.label
                            icon: modelData.icon ?? ""
                            bold: true
                            textColor: "#373738"
                            onActivated: {
                                root.close();
                                Apps.run(modelData);
                            }
                        }
                    }

                    Separator {
                        visible: Apps.recentApplications.length > 0
                        source: root.bitmaps + "proglist-separator.png"
                    }

                    Repeater {
                        model: Apps.recentApplications.slice(0, 6)

                        MenuRow {
                            required property DesktopEntry modelData

                            label: modelData.name
                            icon: modelData.icon
                            iconSize: 24
                            textColor: "#373738"
                            onActivated: {
                                root.close();
                                Apps.launch(modelData);
                            }
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                    }

                    Separator {
                        source: root.bitmaps + "proglist-separator.png"
                    }
                }
            }

            // StartPanel.MorePrograms, with MoreProgramsArrow (hot while selected).
            BorderImage {
                anchors.top: left.bottom
                width: menu.columnWidth
                height: menu.moreProgramsHeight
                source: root.bitmaps + "moreprograms.png"
                border.left: 3
                border.right: 0
                border.top: 0
                border.bottom: 1
                smooth: false

                Item {
                    id: allPrograms

                    readonly property bool navigable: true
                    readonly property bool highlighted: root.current === allPrograms || root.programsOpen

                    signal activated

                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    anchors.bottomMargin: 6
                    onActivated: root.openPrograms(true)

                    Highlight {
                        anchors.fill: parent
                        visible: allPrograms.highlighted
                    }

                    Row {
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "All Programs"
                            color: allPrograms.highlighted ? "#ffffff" : "#373738"
                            font.family: Theme.fontSans
                            font.pixelSize: Theme.fontSize
                            font.bold: true
                        }

                        Image {
                            anchors.verticalCenter: parent.verticalCenter
                            source: root.bitmaps + (allPrograms.highlighted ? "moreprograms-arrow-hot.png" : "moreprograms-arrow.png")
                            smooth: false
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: {
                            root.current = allPrograms;
                            root.openPrograms(false);
                        }
                        onExited: {
                            if (root.current === allPrograms)
                                root.current = null;
                        }
                        onClicked: root.openPrograms(false)
                    }
                }
            }

            // StartPanel.PlacesList
            BorderImage {
                x: menu.columnWidth
                width: menu.columnWidth
                height: parent.height
                source: root.bitmaps + "placeslist.png"
                border.left: 172
                border.right: 7
                border.top: 3
                border.bottom: 1
                smooth: false

                ColumnLayout {
                    id: rightColumn

                    anchors.fill: parent
                    anchors.leftMargin: 4
                    anchors.rightMargin: 6
                    anchors.topMargin: 9
                    anchors.bottomMargin: 5
                    spacing: 0

                    MenuRow {
                        label: "My Documents"
                        icon: "folder-documents"
                        iconSize: 24
                        bold: true
                        textColor: "#0a246a"
                        onActivated: root.openFolder(root.home + "/Documents")
                    }

                    MenuRow {
                        label: "My Pictures"
                        icon: "folder-pictures"
                        iconSize: 24
                        bold: true
                        textColor: "#0a246a"
                        onActivated: root.openFolder(root.home + "/Pictures")
                    }

                    MenuRow {
                        label: "My Music"
                        icon: "folder-music"
                        iconSize: 24
                        bold: true
                        textColor: "#0a246a"
                        onActivated: root.openFolder(root.home + "/Music")
                    }

                    MenuRow {
                        label: "My Computer"
                        icon: "computer"
                        iconSize: 24
                        bold: true
                        textColor: "#0a246a"
                        onActivated: root.openFolder(root.home + "/")
                    }

                    Separator {
                        source: root.bitmaps + "placeslist-separator.png"
                    }

                    MenuRow {
                        label: "Control Panel"
                        icon: "preferences-desktop-theme"
                        iconSize: 24
                        textColor: "#0a246a"
                        onActivated: {
                            root.close();
                            root.themesRequested();
                        }
                    }

                    MenuRow {
                        label: "Run..."
                        icon: "system-run"
                        iconSize: 24
                        textColor: "#0a246a"
                        onActivated: {
                            root.close();
                            root.launcherRequested();
                        }
                    }

                    MenuRow {
                        label: "Search"
                        icon: "search"
                        iconSize: 24
                        textColor: "#0a246a"
                        onActivated: {
                            root.close();
                            root.launcherRequested();
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                    }
                }
            }
        }

        // StartPanel.Logoff
        BorderImage {
            y: menu.headerHeight + body.height
            width: parent.width
            height: menu.footerHeight
            source: root.bitmaps + "logoff.png"
            border.left: 49
            border.right: 47
            border.top: 0
            border.bottom: 38
            smooth: false

            Row {
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 1
                spacing: 6

                FooterButton {
                    label: "Log Off"
                    bitmap: "logoff-button"
                    onActivated: root.confirmSession("logoff")
                }

                FooterButton {
                    label: "Turn Off Computer"
                    bitmap: "turnoff-button"
                    onActivated: root.confirmSession("shutdown")
                }
            }
        }
    }

    // StartMenu::Toolbar: the All Programs flyout, with Toolbar.Button's hot and
    // pressed images behind the selected entry.
    Item {
        id: programs

        readonly property real maxHeight: root.height

        visible: root.programsOpen
        x: menu.x + menu.width - 2
        width: 260
        height: Math.min(programList.contentHeight + 7, programs.maxHeight)
        y: Math.max(0, Math.min(root.programsBottom, root.height) - height)

        // XP's menu drop shadow is a window effect, not part of the visual style.
        Rectangle {
            x: 3
            y: 3
            width: parent.width
            height: parent.height
            color: Qt.rgba(0, 0, 0, 0.3)
        }

        BorderImage {
            anchors.fill: parent
            source: root.bitmaps + "programs.png"
            border.left: 6
            border.right: 5
            border.top: 3
            border.bottom: 4
            smooth: false

            MouseArea {
                anchors.fill: parent
            }

            ListView {
                id: programList

                anchors.fill: parent
                anchors.topMargin: 3
                anchors.bottomMargin: 4
                anchors.rightMargin: 5
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: Apps.applications

                ScrollBar.vertical: ScrollBar {}

                delegate: Item {
                    id: entry

                    required property DesktopEntry modelData
                    required property int index
                    readonly property bool highlighted: ListView.isCurrentItem

                    function launch() {
                        root.close();
                        Apps.launch(entry.modelData);
                    }

                    width: ListView.view.width
                    height: 22

                    BorderImage {
                        anchors.fill: parent
                        visible: entry.highlighted
                        source: root.bitmaps + (entryArea.pressed ? "programs-item-pressed.png" : "programs-item-hot.png")
                        border.left: 6
                        border.right: 1
                        smooth: false
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 6

                        IconImage {
                            implicitSize: 16
                            source: Apps.iconSource(entry.modelData.icon)
                        }

                        Text {
                            Layout.fillWidth: true
                            text: entry.modelData.name
                            elide: Text.ElideRight
                            color: entry.highlighted ? "#ffffff" : "#000000"
                            font.family: Theme.fontSans
                            font.pixelSize: Theme.fontSize
                        }
                    }

                    MouseArea {
                        id: entryArea

                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: programList.currentIndex = entry.index
                        onClicked: entry.launch()
                    }
                }
            }
        }
    }
}
