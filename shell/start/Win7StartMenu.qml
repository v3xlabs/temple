pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "../theme"
import "../apps"
import "../session"
import "../windows"

PanelWindow {
    id: root

    property bool open: false
    property bool allPrograms: false
    property bool powerMenuOpen: false

    signal launcherRequested
    signal themesRequested

    readonly property color tint: Theme.barTokens.win7.tint
    readonly property string home: Quickshell.env("HOME")

    readonly property var pinned: Apps.commands.map(command => ({
                label: command.label,
                icon: command.icon,
                run: () => Apps.run(command)
            }))
    readonly property var recent: Apps.recentApplications.map(app => root.entry(app))
    readonly property var programs: Apps.applications.map(app => root.entry(app))
    readonly property string needle: search.text.trim().toLowerCase()
    readonly property bool searching: needle !== ""
    readonly property var matches: searching ? programs.filter(program => program.label.toLowerCase().includes(needle)) : []
    readonly property bool compact: searching || allPrograms
    readonly property var leftEntries: searching ? matches : allPrograms ? programs : pinned.concat(recent)

    function entry(app: DesktopEntry): var {
        return {
            label: app.name,
            icon: app.icon,
            run: () => Apps.launch(app)
        };
    }

    function toggle(target: ShellScreen) {
        if (open && screen === target) {
            close();
            return;
        }
        screen = target;
        allPrograms = false;
        powerMenuOpen = false;
        search.text = "";
        open = true;
        search.forceActiveFocus();
    }

    function close() {
        open = false;
        powerMenuOpen = false;
    }

    // The overlay covers one screen; a window focused from elsewhere closes it.
    Connections {
        target: Windows
        function onActiveChanged() {
            if (root.open && Windows.active !== null)
                root.close();
        }
    }

    function act(run) {
        close();
        run();
    }

    function openFolder(path: string) {
        act(() => Quickshell.execDetached(["xdg-open", path]));
    }

    function confirm(action: string) {
        confirmOn(screen, action);
    }

    // Also used by the launcher's session commands.
    function confirmOn(target: ShellScreen, action: string) {
        close();
        dialog.show(target, action);
    }

    function lock() {
        close();
        Session.lock();
    }

    visible: open
    WlrLayershell.namespace: "temple-startmenu"
    BackgroundEffect.blurRegion: Region {
        item: Theme.blur ? menu : null
        radius: menu.radius
    }
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

    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Rectangle {
        id: menu

        anchors.left: parent.left
        anchors.bottom: parent.bottom
        width: 400
        height: 540
        radius: 6
        color: Qt.alpha(root.tint, 0.75)
        border.width: 1
        border.color: "#40ffffff"

        MouseArea {
            anchors.fill: parent
            onClicked: root.powerMenuOpen = false
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 1
            height: 60
            radius: 5
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: "#26ffffff"
                }
                GradientStop {
                    position: 1
                    color: "#00ffffff"
                }
            }
        }

        Rectangle {
            id: leftPane

            x: 8
            y: 8
            width: 250
            height: parent.height - 8 - 44
            radius: 4
            color: "#1d2633"
            border.width: 1
            border.color: "#0a0f16"

            ListView {
                id: list

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: footer.top
                anchors.margins: 4
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: root.leftEntries

                delegate: LeftRow {
                    required property var modelData
                    required property int index

                    width: list.width
                    height: root.compact ? 24 : 34
                    iconSize: root.compact ? 16 : 24
                    label: modelData.label
                    icon: modelData.icon ?? ""
                    selected: root.searching && index === 0
                    separatorBelow: !root.compact && index === root.pinned.length - 1 && root.recent.length > 0
                    onActivated: root.act(modelData.run)
                }
            }

            Text {
                anchors.centerIn: list
                visible: root.searching && root.matches.length === 0
                text: "No items match your search."
                color: "#8a9bb0"
                font.family: Theme.fontSans
                font.pixelSize: Theme.fontSize
            }

            Item {
                id: footer

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 4
                height: root.searching ? 0 : 33
                visible: !root.searching

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 6
                    anchors.rightMargin: 6
                    height: 1
                    color: "#3a4758"
                }

                LeftRow {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 30
                    iconSize: 0
                    label: root.allPrograms ? "Back" : "All Programs"
                    bold: true
                    triangle: root.allPrograms ? -1 : 1
                    onActivated: {
                        root.allPrograms = !root.allPrograms;
                        list.positionViewAtBeginning();
                    }
                }
            }
        }

        Rectangle {
            id: searchBox

            x: 8
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 8
            width: leftPane.width
            height: 28
            radius: 4
            color: "#2a3646"
            border.width: 1
            border.color: search.activeFocus ? Qt.alpha(Theme.accent, 0.8) : "#4a5868"

            TextInput {
                id: search

                anchors.left: parent.left
                anchors.right: searchIcon.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                leftPadding: 8
                rightPadding: 4
                verticalAlignment: TextInput.AlignVCenter
                clip: true
                color: "#e8eef5"
                selectionColor: Theme.selection
                font.family: Theme.fontSans
                font.pixelSize: Theme.fontSize
                onTextChanged: list.positionViewAtBeginning()

                Text {
                    anchors.fill: parent
                    leftPadding: 8
                    verticalAlignment: Text.AlignVCenter
                    visible: search.text === ""
                    text: "Search programs and files"
                    color: "#8a9bb0"
                    font.family: Theme.fontSans
                    font.pixelSize: Theme.fontSize
                    font.italic: true
                }

                Keys.onEscapePressed: {
                    if (root.powerMenuOpen)
                        root.powerMenuOpen = false;
                    else if (search.text !== "")
                        search.text = "";
                    else
                        root.close();
                }
                Keys.onReturnPressed: if (root.matches.length > 0)
                    root.act(root.matches[0].run)
                Keys.onEnterPressed: if (root.matches.length > 0)
                    root.act(root.matches[0].run)
            }

            IconImage {
                id: searchIcon

                anchors.right: parent.right
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                implicitSize: 16
                source: Apps.iconSource("search")
            }
        }

        Column {
            id: rightPane

            anchors.left: leftPane.right
            anchors.leftMargin: 8
            anchors.right: parent.right
            anchors.rightMargin: 8
            y: 8
            spacing: 2

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 64
                height: 64
                radius: 7
                border.width: 1
                border.color: "#c0ffffff"
                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: "#f0f6fc"
                    }
                    GradientStop {
                        position: 0.5
                        color: "#b8c8da"
                    }
                    GradientStop {
                        position: 1
                        color: "#8098b4"
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 5
                    radius: 3
                    color: "#2a3646"
                    border.width: 1
                    border.color: "#60000000"

                    IconImage {
                        anchors.centerIn: parent
                        implicitSize: 44
                        source: Apps.iconSource("user-identity")
                    }
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 1
                    height: parent.height / 2
                    radius: 6
                    gradient: Gradient {
                        GradientStop {
                            position: 0
                            color: "#80ffffff"
                        }
                        GradientStop {
                            position: 1
                            color: "#10ffffff"
                        }
                    }
                }
            }

            Item {
                width: 1
                height: 8
            }

            Repeater {
                model: [
                    {
                        label: Session.user,
                        run: () => root.openFolder(root.home)
                    },
                    {
                        label: "Documents",
                        run: () => root.openFolder(root.home + "/Documents")
                    },
                    {
                        label: "Pictures",
                        run: () => root.openFolder(root.home + "/Pictures")
                    },
                    {
                        label: "Music",
                        run: () => root.openFolder(root.home + "/Music")
                    },
                    {
                        label: "Computer",
                        run: () => root.openFolder("/")
                    },
                    {
                        separator: true
                    },
                    {
                        label: "Control Panel",
                        run: () => root.act(() => root.themesRequested())
                    },
                    {
                        label: "Run...",
                        run: () => root.act(() => root.launcherRequested())
                    }
                ]

                Item {
                    id: link

                    required property var modelData

                    width: rightPane.width
                    height: link.modelData.separator ? 9 : 30

                    Rectangle {
                        visible: link.modelData.separator ?? false
                        anchors.verticalCenter: parent.verticalCenter
                        x: 4
                        width: parent.width - 8
                        height: 1
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop {
                                position: 0
                                color: "#00ffffff"
                            }
                            GradientStop {
                                position: 0.5
                                color: "#50ffffff"
                            }
                            GradientStop {
                                position: 1
                                color: "#00ffffff"
                            }
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: 3
                        visible: !(link.modelData.separator ?? false) && linkMouse.containsMouse
                        border.width: 1
                        border.color: "#70ffffff"
                        gradient: Gradient {
                            GradientStop {
                                position: 0
                                color: "#40ffffff"
                            }
                            GradientStop {
                                position: 1
                                color: "#14ffffff"
                            }
                        }
                    }

                    Text {
                        visible: !(link.modelData.separator ?? false)
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 10
                        anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        text: link.modelData.label ?? ""
                        elide: Text.ElideRight
                        color: "#ffffff"
                        style: Text.Raised
                        styleColor: "#60000000"
                        font.family: Theme.fontSans
                        font.pixelSize: Theme.fontSize
                    }

                    MouseArea {
                        id: linkMouse

                        anchors.fill: parent
                        enabled: !(link.modelData.separator ?? false)
                        hoverEnabled: true
                        onClicked: link.modelData.run()
                    }
                }
            }
        }

        Row {
            id: shutdown

            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: searchBox.verticalCenter

            GlassButton {
                width: 78
                height: 24
                leftRounded: true
                onClicked: root.confirm("shutdown")

                Text {
                    anchors.centerIn: parent
                    text: "Shut down"
                    color: "#ffffff"
                    style: Text.Raised
                    styleColor: "#60000000"
                    font.family: Theme.fontSans
                    font.pixelSize: Theme.fontSize
                }
            }

            GlassButton {
                id: arrow

                width: 22
                height: 24
                rightRounded: true
                pressed: root.powerMenuOpen
                onClicked: root.powerMenuOpen = !root.powerMenuOpen

                Text {
                    anchors.centerIn: parent
                    text: "▸"
                    color: "#ffffff"
                    font.pixelSize: Theme.fontSize
                }
            }
        }

        Rectangle {
            id: powerMenu

            visible: root.powerMenuOpen
            x: shutdown.x + shutdown.width + 4
            y: shutdown.y + shutdown.height - height
            width: 150
            height: powerColumn.implicitHeight + 8
            radius: 3
            color: "#1d2633"
            border.width: 1
            border.color: "#5c6f85"

            MouseArea {
                anchors.fill: parent
            }

            Column {
                id: powerColumn

                x: 4
                y: 4
                width: parent.width - 8

                Repeater {
                    model: [
                        {
                            label: "Log off",
                            icon: "system-log-out",
                            run: () => root.confirm("logout")
                        },
                        {
                            label: "Lock",
                            icon: "system-lock-screen",
                            run: () => root.lock()
                        },
                        {
                            separator: true
                        },
                        {
                            label: "Restart",
                            icon: "system-reboot",
                            run: () => root.confirm("reboot")
                        },
                        {
                            label: "Sleep",
                            icon: "system-suspend",
                            run: () => root.confirm("suspend")
                        }
                    ]

                    Item {
                        id: powerItem

                        required property var modelData

                        width: powerColumn.width
                        height: powerItem.modelData.separator ? 7 : 26

                        Rectangle {
                            visible: powerItem.modelData.separator ?? false
                            anchors.verticalCenter: parent.verticalCenter
                            x: 4
                            width: parent.width - 8
                            height: 1
                            color: "#3a4758"
                        }

                        LeftRow {
                            visible: !(powerItem.modelData.separator ?? false)
                            anchors.fill: parent
                            iconSize: 16
                            label: powerItem.modelData.label ?? ""
                            icon: powerItem.modelData.icon ?? ""
                            onActivated: powerItem.modelData.run()
                        }
                    }
                }
            }
        }
    }

    Win7SessionDialog {
        id: dialog
    }

    // A row in the dark program list: icon, label, light-blue hover highlight.
    component LeftRow: Item {
        id: row

        property string label
        property string icon
        property int iconSize: 24
        property bool selected: false
        property bool bold: false
        property bool separatorBelow: false
        // 1 points right, -1 points left, 0 hides the triangle.
        property int triangle: 0

        signal activated

        Rectangle {
            anchors.fill: parent
            anchors.bottomMargin: row.separatorBelow ? 5 : 0
            radius: 3
            visible: rowMouse.containsMouse || row.selected
            border.width: 1
            border.color: "#7eb4ea"
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: "#507eb4ea"
                }
                GradientStop {
                    position: 1
                    color: "#207eb4ea"
                }
            }
        }

        Text {
            visible: row.triangle !== 0
            anchors.verticalCenter: rowLabel.verticalCenter
            x: row.triangle > 0 ? rowLabel.x + rowLabel.implicitWidth + 8 : 8
            text: row.triangle > 0 ? "▶" : "◀"
            color: "#7eb4ea"
            font.pixelSize: Theme.fontSize - 4
        }

        IconImage {
            visible: row.iconSize > 0
            x: 6
            y: (row.height - (row.separatorBelow ? 5 : 0) - height) / 2
            implicitSize: row.iconSize
            source: row.iconSize > 0 ? Apps.iconSource(row.icon) : ""
        }

        Text {
            id: rowLabel

            anchors.left: parent.left
            anchors.leftMargin: row.iconSize > 0 ? 6 + row.iconSize + 8 : row.triangle < 0 ? 24 : 10
            anchors.right: parent.right
            anchors.rightMargin: row.triangle > 0 ? 24 : 6
            y: (row.height - (row.separatorBelow ? 5 : 0) - height) / 2
            text: row.label
            elide: Text.ElideRight
            color: "#e8eef5"
            font.family: Theme.fontSans
            font.pixelSize: Theme.fontSize
            font.bold: row.bold
        }

        Rectangle {
            visible: row.separatorBelow
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 2
            x: 6
            width: parent.width - 12
            height: 1
            color: "#3a4758"
        }

        MouseArea {
            id: rowMouse

            anchors.fill: parent
            hoverEnabled: true
            onClicked: row.activated()
        }
    }

    // One half of the split Shut down button.
    component GlassButton: Item {
        id: glass

        property bool leftRounded: false
        property bool rightRounded: false
        property bool pressed: false

        signal clicked

        Rectangle {
            anchors.fill: parent
            topLeftRadius: glass.leftRounded ? 3 : 0
            bottomLeftRadius: glass.leftRounded ? 3 : 0
            topRightRadius: glass.rightRounded ? 3 : 0
            bottomRightRadius: glass.rightRounded ? 3 : 0
            border.width: 1
            border.color: "#80ffffff"
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: glass.pressed ? "#30ffffff" : glassMouse.containsMouse ? "#60ffffff" : "#40ffffff"
                }
                GradientStop {
                    position: 0.5
                    color: glass.pressed ? "#18ffffff" : glassMouse.containsMouse ? "#30ffffff" : "#18ffffff"
                }
                GradientStop {
                    position: 0.51
                    color: glass.pressed ? "#08ffffff" : glassMouse.containsMouse ? "#20ffffff" : "#06ffffff"
                }
                GradientStop {
                    position: 1
                    color: glass.pressed ? "#20ffffff" : glassMouse.containsMouse ? "#40ffffff" : "#20ffffff"
                }
            }
        }

        MouseArea {
            id: glassMouse

            anchors.fill: parent
            hoverEnabled: true
            onClicked: glass.clicked()
        }
    }
}
