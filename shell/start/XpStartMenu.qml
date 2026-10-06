pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import "../theme"
import "../apps"
import "../session"

PanelWindow {
    id: root

    signal launcherRequested
    signal themesRequested

    property bool open: false
    property bool programsOpen: false
    // Window y of the All Programs row's bottom edge; the flyout grows upward from there.
    property real programsBottom: 0

    readonly property string home: Quickshell.env("HOME")

    function toggle(target: ShellScreen) {
        if (open) {
            close();
            return;
        }
        screen = target;
        programsOpen = false;
        open = true;
        focusScope.forceActiveFocus();
    }

    function close() {
        programsOpen = false;
        open = false;
    }

    // The overlay covers one screen; a click on another screen or a window
    // focused from elsewhere shows up as a focus change instead.
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (root.open && (event.name === "focusedmon" || (event.name === "activewindowv2" && event.data !== "")))
                root.close();
        }
    }

    function openFolder(path: string) {
        close();
        Quickshell.execDetached(["xdg-open", path]);
    }

    function openPrograms() {
        programsBottom = allPrograms.mapToItem(root.contentItem, 0, allPrograms.height).y;
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

    component MenuRow: Rectangle {
        id: row

        property string label
        property string icon
        property int iconSize: 32
        property bool bold: false
        property color textColor: "#000000"

        signal activated
        signal hovered

        Layout.fillWidth: true
        implicitHeight: row.iconSize + 8
        color: rowArea.containsMouse ? "#316ac5" : "transparent"

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
                color: rowArea.containsMouse ? "#ffffff" : row.textColor
                font.family: Theme.fontSans
                font.pixelSize: Theme.fontSize
                font.bold: row.bold
            }
        }

        MouseArea {
            id: rowArea

            anchors.fill: parent
            hoverEnabled: true
            onEntered: row.hovered()
            onClicked: row.activated()
        }
    }

    component Separator: Rectangle {
        Layout.fillWidth: true
        Layout.leftMargin: 8
        Layout.rightMargin: 8
        Layout.topMargin: 3
        Layout.bottomMargin: 3
        implicitHeight: 1
    }

    component BlueBand: Gradient {
        GradientStop {
            position: 0
            color: "#3d8af7"
        }
        GradientStop {
            position: 0.12
            color: "#2a7af0"
        }
        GradientStop {
            position: 0.55
            color: "#1c5fd9"
        }
        GradientStop {
            position: 1
            color: "#1650c8"
        }
    }

    component FooterButton: Item {
        id: footerButton

        property string label
        property string icon
        property color tile

        signal activated

        implicitWidth: footerRow.implicitWidth + 8
        implicitHeight: 30

        Row {
            id: footerRow

            anchors.centerIn: parent
            spacing: 5

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 24
                height: 24
                radius: 4
                antialiasing: true
                color: footerArea.containsMouse ? Qt.lighter(footerButton.tile, 1.2) : footerButton.tile
                border.width: 1
                border.color: "#ffffff"

                IconImage {
                    anchors.centerIn: parent
                    implicitSize: 18
                    source: Apps.iconSource(footerButton.icon)
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: footerButton.label
                color: "#ffffff"
                font.family: Theme.fontSans
                font.pixelSize: Theme.fontSize
                font.underline: footerArea.containsMouse
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
        Keys.onEscapePressed: {
            if (root.programsOpen)
                root.programsOpen = false;
            else
                root.close();
        }
    }

    Item {
        id: menu

        readonly property int cornerRadius: 8
        readonly property int headerHeight: 64
        readonly property int footerHeight: 44

        x: 0
        y: parent.height - height
        width: 380
        height: headerHeight + body.height + footerHeight
        // Rounding only the top corners: the frame extends past the bottom edge and gets clipped.
        clip: true

        MouseArea {
            anchors.fill: parent
        }

        Rectangle {
            width: parent.width
            height: parent.height + menu.cornerRadius
            radius: menu.cornerRadius
            antialiasing: true
            color: "#1650c8"
        }

        Item {
            id: header

            width: parent.width
            height: menu.headerHeight
            clip: true

            Rectangle {
                width: parent.width
                height: parent.height + menu.cornerRadius
                radius: menu.cornerRadius
                antialiasing: true
                gradient: BlueBand {}
            }

            Rectangle {
                id: picture

                x: 8
                anchors.verticalCenter: parent.verticalCenter
                width: 48
                height: 48
                radius: 5
                antialiasing: true
                border.width: 2
                border.color: "#ffffff"
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

            Item {
                anchors.left: picture.right
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: userLabel.implicitWidth + 1
                implicitHeight: userLabel.implicitHeight + 1

                Text {
                    x: 1
                    y: 1
                    text: userLabel.text
                    font: userLabel.font
                    color: Qt.rgba(0, 0, 0, 0.4)
                }

                Text {
                    id: userLabel

                    text: Session.user
                    color: "#ffffff"
                    font.family: Theme.fontSans
                    font.pixelSize: Theme.fontSize + 5
                    font.bold: true
                }
            }

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 2
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop {
                        position: 0
                        color: "#1650c8"
                    }
                    GradientStop {
                        position: 0.5
                        color: "#f0a050"
                    }
                    GradientStop {
                        position: 1
                        color: "#1650c8"
                    }
                }
            }
        }

        Item {
            id: body

            x: 2
            y: menu.headerHeight
            width: parent.width - 4
            height: Math.max(372, leftColumn.implicitHeight, rightColumn.implicitHeight)

            Rectangle {
                id: left

                width: Math.round(parent.width * 0.52)
                height: parent.height
                color: "#ffffff"

                ColumnLayout {
                    id: leftColumn

                    anchors.fill: parent
                    anchors.topMargin: 6
                    anchors.bottomMargin: 6
                    spacing: 0

                    Repeater {
                        model: Apps.commands

                        MenuRow {
                            required property var modelData

                            label: modelData.label
                            icon: modelData.icon ?? ""
                            bold: true
                            onHovered: root.programsOpen = false
                            onActivated: {
                                root.close();
                                Apps.run(modelData);
                            }
                        }
                    }

                    Separator {
                        visible: Apps.recentApplications.length > 0
                        color: "#d6d3ce"
                    }

                    Repeater {
                        model: Apps.recentApplications.slice(0, 6)

                        MenuRow {
                            required property DesktopEntry modelData

                            label: modelData.name
                            icon: modelData.icon
                            iconSize: 24
                            onHovered: root.programsOpen = false
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
                        color: "#d6d3ce"
                    }

                    Rectangle {
                        id: allPrograms

                        readonly property bool highlighted: allProgramsArea.containsMouse || root.programsOpen

                        Layout.fillWidth: true
                        implicitHeight: 30
                        color: allPrograms.highlighted ? "#316ac5" : "transparent"

                        Row {
                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "All Programs"
                                color: allPrograms.highlighted ? "#ffffff" : "#000000"
                                font.family: Theme.fontSans
                                font.pixelSize: Theme.fontSize
                                font.bold: true
                            }

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 20
                                height: 20
                                radius: 4
                                antialiasing: true
                                border.width: 1
                                border.color: "#1f7a16"
                                gradient: Gradient {
                                    GradientStop {
                                        position: 0
                                        color: "#7ed96a"
                                    }
                                    GradientStop {
                                        position: 1
                                        color: "#2e9a22"
                                    }
                                }

                                Canvas {
                                    anchors.fill: parent
                                    onPaint: {
                                        const ctx = getContext("2d");
                                        ctx.reset();
                                        ctx.fillStyle = "#ffffff";
                                        ctx.beginPath();
                                        ctx.moveTo(width * 0.35, height * 0.25);
                                        ctx.lineTo(width * 0.72, height * 0.5);
                                        ctx.lineTo(width * 0.35, height * 0.75);
                                        ctx.closePath();
                                        ctx.fill();
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: allProgramsArea

                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: root.openPrograms()
                            onClicked: root.openPrograms()
                        }
                    }
                }
            }

            Rectangle {
                anchors.left: left.right
                anchors.right: parent.right
                height: parent.height
                color: "#d3e5fa"

                Rectangle {
                    width: 1
                    height: parent.height
                    color: "#95bdee"
                }

                ColumnLayout {
                    id: rightColumn

                    anchors.fill: parent
                    anchors.leftMargin: 1
                    anchors.topMargin: 6
                    anchors.bottomMargin: 6
                    spacing: 0

                    MenuRow {
                        label: "My Documents"
                        icon: "folder-documents"
                        iconSize: 24
                        bold: true
                        textColor: "#0a246a"
                        onHovered: root.programsOpen = false
                        onActivated: root.openFolder(root.home + "/Documents")
                    }

                    MenuRow {
                        label: "My Pictures"
                        icon: "folder-pictures"
                        iconSize: 24
                        bold: true
                        textColor: "#0a246a"
                        onHovered: root.programsOpen = false
                        onActivated: root.openFolder(root.home + "/Pictures")
                    }

                    MenuRow {
                        label: "My Music"
                        icon: "folder-music"
                        iconSize: 24
                        bold: true
                        textColor: "#0a246a"
                        onHovered: root.programsOpen = false
                        onActivated: root.openFolder(root.home + "/Music")
                    }

                    MenuRow {
                        label: "My Computer"
                        icon: "computer"
                        iconSize: 24
                        bold: true
                        textColor: "#0a246a"
                        onHovered: root.programsOpen = false
                        onActivated: root.openFolder(root.home + "/")
                    }

                    Separator {
                        color: "#95bdee"
                    }

                    MenuRow {
                        label: "Control Panel"
                        icon: "preferences-desktop-theme"
                        iconSize: 24
                        textColor: "#0a246a"
                        onHovered: root.programsOpen = false
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
                        onHovered: root.programsOpen = false
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
                        onHovered: root.programsOpen = false
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

        Rectangle {
            y: menu.headerHeight + body.height
            width: parent.width
            height: menu.footerHeight
            gradient: BlueBand {}

            Row {
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                FooterButton {
                    label: "Log Off"
                    icon: "system-log-out"
                    tile: "#e8a21b"
                    onActivated: root.confirmSession("logoff")
                }

                FooterButton {
                    label: "Turn Off Computer"
                    icon: "system-shutdown"
                    tile: "#d9432f"
                    onActivated: root.confirmSession("shutdown")
                }
            }
        }
    }

    Item {
        id: programs

        readonly property real maxHeight: root.height

        visible: root.programsOpen
        x: menu.x + menu.width - 2
        width: 260
        height: Math.min(programList.contentHeight + 4, programs.maxHeight)
        y: Math.max(0, Math.min(root.programsBottom, root.height) - height)

        Rectangle {
            x: 3
            y: 3
            width: parent.width
            height: parent.height
            color: Qt.rgba(0, 0, 0, 0.3)
        }

        Rectangle {
            anchors.fill: parent
            color: "#ffffff"
            border.width: 1
            border.color: "#7a96df"

            MouseArea {
                anchors.fill: parent
            }

            ListView {
                id: programList

                anchors.fill: parent
                anchors.margins: 2
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: Apps.applications

                ScrollBar.vertical: ScrollBar {}

                delegate: Rectangle {
                    id: entry

                    required property DesktopEntry modelData

                    width: ListView.view.width
                    height: 22
                    color: entryArea.containsMouse ? "#316ac5" : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 6
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
                            color: entryArea.containsMouse ? "#ffffff" : "#000000"
                            font.family: Theme.fontSans
                            font.pixelSize: Theme.fontSize
                        }
                    }

                    MouseArea {
                        id: entryArea

                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            root.close();
                            Apps.launch(entry.modelData);
                        }
                    }
                }
            }
        }
    }
}
