pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Networking
import "../theme"

// Connection state of the network devices; left click opens the network list.
Item {
    id: root

    property int size: 16

    readonly property var devices: Networking.devices.values
    readonly property var wifiDevices: root.devices.filter(device => device.type === DeviceType.Wifi)
    readonly property var wiredDevices: root.devices.filter(device => device.type === DeviceType.Wired)
    readonly property WiredDevice wired: root.wiredDevices.find(device => device.connected) ?? null
    readonly property WifiNetwork wifi: {
        for (const device of root.wifiDevices) {
            const network = device.networks.values.find(network => network.connected);
            if (network)
                return network;
        }
        return null;
    }
    readonly property bool connected: root.wired !== null || root.wifi !== null
    readonly property bool connecting: root.devices.some(device => device.state === ConnectionState.Connecting)
    readonly property string connectionName: root.wired ? (root.wired.network?.name || root.wired.name) : root.wifi ? root.wifi.name : ""
    readonly property string iconName: root.wired ? "network-wired" : root.wifi ? root.signalIcon(root.wifi.signalStrength) : root.wiredDevices.length > 0 && root.wifiDevices.length === 0 ? "network-wired-disconnected" : "network-offline"
    readonly property string status: {
        if (root.connecting && !root.connected)
            return "Connecting…";
        if (!root.connected)
            return root.devices.length === 0 ? "No network devices" : "Not connected";
        switch (Networking.connectivity) {
        case NetworkConnectivity.Full:
            return "Internet access";
        case NetworkConnectivity.Limited:
            return "Limited access";
        case NetworkConnectivity.Portal:
            return "Sign-in required";
        case NetworkConnectivity.None:
            return "No Internet access";
        default:
            return "Connected";
        }
    }

    function signalIcon(strength: real): string {
        if (strength >= 0.8)
            return "network-wireless-signal-excellent";
        if (strength >= 0.6)
            return "network-wireless-signal-good";
        if (strength >= 0.4)
            return "network-wireless-signal-ok";
        if (strength >= 0.2)
            return "network-wireless-signal-weak";
        return "network-wireless-signal-none";
    }

    implicitWidth: TrayStyle.barLabels ? barLabel.implicitWidth : root.size
    implicitHeight: root.size

    TrayIcon {
        visible: !TrayStyle.barLabels
        anchors.fill: parent
        implicitSize: root.size
        name: root.iconName
        tint: TrayStyle.barIconTint
    }

    Text {
        id: barLabel

        visible: TrayStyle.barLabels
        anchors.verticalCenter: parent.verticalCenter
        text: root.connected ? "Net:Up" : root.connecting ? "Net:..." : "Net:Down"
        color: area.containsMouse || popup.visible ? TrayStyle.barHighlight : TrayStyle.barIconTint
        font.family: TrayStyle.font
        font.pixelSize: TrayStyle.fontSize
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        onClicked: popup.toggle()
    }

    TrayTooltip {
        trigger: root
        text: root.connected ? `${root.connectionName}\n${root.status}` : root.status
        hovered: area.containsMouse && !popup.visible
    }

    component Separator: Rectangle {
        height: Theme.lineWidth
        color: TrayStyle.separator
    }

    component Label: Text {
        color: TrayStyle.text
        font.family: TrayStyle.font
        font.pixelSize: TrayStyle.fontSize
    }

    component SignalBars: Item {
        id: bars

        property real strength: 0
        property color color: TrayStyle.text

        implicitWidth: 4 * 4 - 1
        implicitHeight: 13

        Repeater {
            model: 4

            Rectangle {
                required property int index

                x: index * 4
                y: bars.height - height
                width: 3
                height: 4 + index * 3
                color: bars.strength > index / 4 ? bars.color : Qt.alpha(bars.color, 0.25)
            }
        }
    }

    component SectionTitle: Item {
        id: title

        property string text
        property string detail

        implicitHeight: 22

        Label {
            id: titleText

            x: 6
            anchors.verticalCenter: parent.verticalCenter
            text: title.text
            font.bold: !Theme.fontBitmap
            color: TrayStyle.network.title
        }

        Label {
            id: detailText

            anchors.left: titleText.right
            anchors.leftMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            text: title.detail
            color: TrayStyle.textMuted
            font.pixelSize: Theme.textSize(-1)
        }

        Separator {
            visible: TrayStyle.network.titleRule
            anchors.left: detailText.right
            anchors.leftMargin: 6
            anchors.right: parent.right
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    component WifiEntry: Column {
        id: entry

        required property WifiNetwork modelData
        property bool askPassword: false
        property string failure: ""

        readonly property bool secured: entry.modelData.security !== WifiSecurityType.Open
        // connectWithPsk only applies to these; enterprise networks need a full connection editor.
        readonly property bool takesPsk: [WifiSecurityType.WpaPsk, WifiSecurityType.Wpa2Psk, WifiSecurityType.Sae].includes(entry.modelData.security)

        function activate() {
            if (entry.modelData.connected)
                return;
            entry.failure = "";
            if (!entry.modelData.known && entry.takesPsk)
                entry.askPassword = true;
            else
                entry.modelData.connect();
        }

        function submit() {
            if (psk.text === "")
                return;
            entry.failure = "";
            entry.askPassword = false;
            entry.modelData.connectWithPsk(psk.text);
            psk.text = "";
        }

        spacing: 2
        onAskPasswordChanged: {
            if (entry.askPassword)
                psk.forceActiveFocus();
        }

        Connections {
            target: entry.modelData

            function onConnectionFailed(reason: int) {
                entry.failure = ConnectionFailReason.toString(reason);
                if (reason === ConnectionFailReason.NoSecrets && entry.takesPsk)
                    entry.askPassword = true;
            }
        }

        TrayRow {
            id: networkRow

            width: entry.width
            icon: root.signalIcon(entry.modelData.signalStrength)
            label: entry.modelData.name
            bold: entry.modelData.connected
            detail: entry.modelData.stateChanging ? ConnectionState.toString(entry.modelData.state) : entry.modelData.connected ? "Connected" : entry.failure
            onActivated: entry.activate()

            Label {
                visible: entry.modelData.connected
                anchors.verticalCenter: parent.verticalCenter
                text: "✓"
                font.bold: true
                color: networkRow.highlighted ? TrayStyle.network.checkHover : TrayStyle.network.check
            }

            TrayIcon {
                visible: entry.secured
                anchors.verticalCenter: parent.verticalCenter
                implicitSize: 16
                name: "object-locked"
                tint: networkRow.iconTint
            }

            SignalBars {
                anchors.verticalCenter: parent.verticalCenter
                strength: entry.modelData.signalStrength
                color: networkRow.textColor
            }

            TrayButton {
                visible: entry.modelData.connected
                anchors.verticalCenter: parent.verticalCenter
                text: "Disconnect"
                onClicked: entry.modelData.disconnect()
            }
        }

        Row {
            visible: entry.askPassword
            x: 28
            spacing: 6

            Rectangle {
                width: entry.width - 28 - connectButton.width - 12
                height: connectButton.height
                radius: TrayStyle.network.field.radius
                color: TrayStyle.network.field.color
                border.width: 1
                border.color: psk.activeFocus ? TrayStyle.accent : TrayStyle.network.field.border

                TextInput {
                    id: psk

                    anchors.fill: parent
                    leftPadding: 5
                    rightPadding: 5
                    verticalAlignment: TextInput.AlignVCenter
                    clip: true
                    echoMode: TextInput.Password
                    color: TrayStyle.text
                    selectionColor: TrayStyle.accent
                    font.family: TrayStyle.font
                    font.pixelSize: TrayStyle.fontSize
                    onAccepted: entry.submit()
                    Keys.onEscapePressed: event => {
                        if (entry.askPassword) {
                            entry.askPassword = false;
                            event.accepted = true;
                        } else {
                            event.accepted = false;
                        }
                    }

                    Label {
                        anchors.fill: parent
                        leftPadding: 5
                        verticalAlignment: Text.AlignVCenter
                        visible: psk.text === ""
                        text: "Security key"
                        color: TrayStyle.textMuted
                    }
                }
            }

            TrayButton {
                id: connectButton

                text: "Connect"
                onClicked: entry.submit()
            }
        }
    }

    TrayPopup {
        id: popup

        trigger: root
        panelWidth: TrayStyle.network.width

        Loader {
            active: TrayStyle.network.banner !== null
            visible: active
            width: parent.width
            sourceComponent: Rectangle {
                height: 26
                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: TrayStyle.network.banner.top
                    }
                    GradientStop {
                        position: 1
                        color: TrayStyle.network.banner.bottom
                    }
                }

                Label {
                    x: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Network Connections"
                    color: TrayStyle.network.banner.text
                    font.bold: true
                }
            }
        }

        Label {
            visible: TrayStyle.network.banner === null
            leftPadding: 6
            text: root.connected ? "Currently connected to:" : root.status
            color: TrayStyle.textMuted
            font.pixelSize: Theme.textSize(-1)
        }

        Item {
            visible: root.connected || TrayStyle.network.banner !== null
            width: parent.width
            height: 40

            TrayIcon {
                id: headerIcon

                x: 6
                anchors.verticalCenter: parent.verticalCenter
                implicitSize: 28
                name: root.iconName
                tint: TrayStyle.iconTint
            }

            Column {
                anchors.left: headerIcon.right
                anchors.leftMargin: 8
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter

                Label {
                    width: parent.width
                    elide: Text.ElideRight
                    text: root.connected ? root.connectionName : "Not connected"
                    font.bold: !Theme.fontBitmap
                }

                Label {
                    width: parent.width
                    elide: Text.ElideRight
                    text: root.status
                    color: TrayStyle.textMuted
                    font.pixelSize: Theme.textSize(-1)
                }
            }
        }

        Separator {
            width: parent.width
        }

        Label {
            visible: root.devices.length === 0
            width: parent.width
            topPadding: 6
            bottomPadding: 6
            horizontalAlignment: Text.AlignHCenter
            text: "No network devices"
            color: TrayStyle.textMuted
        }

        Rectangle {
            visible: root.devices.length > 0
            width: parent.width
            height: Math.min(sections.implicitHeight, 340) + 2
            color: TrayStyle.network.list.color
            border.width: 1
            border.color: TrayStyle.network.list.border

            Flickable {
                anchors.fill: parent
                anchors.margins: 1
                clip: true
                contentHeight: sections.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: sections

                    width: parent.width
                    spacing: 2

                    Repeater {
                        model: root.wiredDevices

                        Column {
                            id: wiredSection

                            required property WiredDevice modelData

                            width: sections.width

                            SectionTitle {
                                width: wiredSection.width
                                text: "Wired"
                                detail: wiredSection.modelData.name
                            }

                            TrayRow {
                                id: wiredRow

                                readonly property WiredDevice device: wiredSection.modelData

                                width: wiredSection.width
                                icon: wiredRow.device.connected ? "network-wired" : "network-wired-disconnected"
                                label: wiredRow.device.network?.name || wiredRow.device.name
                                bold: wiredRow.device.connected
                                detail: !wiredRow.device.hasLink ? "Cable unplugged" : wiredRow.device.linkSpeed > 0 ? `${ConnectionState.toString(wiredRow.device.state)} · ${wiredRow.device.linkSpeed} Mb/s` : ConnectionState.toString(wiredRow.device.state)
                                onActivated: {
                                    if (!wiredRow.device.connected && wiredRow.device.hasLink)
                                        wiredRow.device.network?.connect();
                                }

                                TrayButton {
                                    visible: wiredRow.device.connected
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Disconnect"
                                    onClicked: wiredRow.device.disconnect()
                                }
                            }
                        }
                    }

                    Repeater {
                        model: root.wifiDevices

                        Column {
                            id: wifiSection

                            required property WifiDevice modelData

                            width: sections.width
                            spacing: 1

                            // The device only keeps its network list fresh while scanning.
                            Binding {
                                target: wifiSection.modelData
                                property: "scannerEnabled"
                                value: popup.visible
                            }

                            SectionTitle {
                                width: wifiSection.width
                                text: "Wireless"
                                detail: wifiSection.modelData.name
                            }

                            Label {
                                visible: !Networking.wifiEnabled
                                leftPadding: 6
                                text: "Wireless is turned off"
                                color: TrayStyle.textMuted
                            }

                            Repeater {
                                // ScriptModel keeps delegates, and a half-typed security key, across re-sorts.
                                model: ScriptModel {
                                    values: Networking.wifiEnabled ? [...wifiSection.modelData.networks.values].filter(network => network.name !== "").sort((a, b) => (b.connected - a.connected) || (b.signalStrength - a.signalStrength)) : []
                                }

                                WifiEntry {
                                    width: wifiSection.width
                                }
                            }
                        }
                    }
                }
            }
        }

        TrayRow {
            visible: root.wifiDevices.length > 0 && !Networking.wifiEnabled && Networking.wifiHardwareEnabled
            width: parent.width
            icon: "network-wireless-signal-excellent"
            label: "Turn on wireless"
            onActivated: Networking.wifiEnabled = true
        }

        Separator {
            width: parent.width
        }

        TrayRow {
            width: parent.width
            link: TrayStyle.network.settingsLink
            icon: "preferences-system-network"
            iconTint: "transparent"
            label: "Network settings"
            onActivated: {
                popup.visible = false;
                Quickshell.execDetached(["nm-connection-editor"]);
            }
        }
    }
}
