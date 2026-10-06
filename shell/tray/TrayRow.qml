import QtQuick
import "../theme"

// A clickable flyout row: optional radio mark and icon, a label with an optional second line, and trailing items.
Rectangle {
    id: row

    property string icon
    property string label
    property string detail
    property bool radio: false
    property bool checked: false
    property bool link: false
    property bool bold: false
    property int iconSize: 16
    // Monochrome status icons follow the text colour; set transparent for colourful icons.
    property color iconTint: row.highlighted ? TrayStyle.hoverIconTint : TrayStyle.iconTint
    default property alias trailing: trailingRow.data

    readonly property bool highlighted: area.containsMouse && !row.link
    readonly property color textColor: row.link ? TrayStyle.link : row.highlighted ? TrayStyle.hoverText : TrayStyle.text

    signal activated

    implicitHeight: Math.max(row.iconSize + 8, labels.implicitHeight + 8, trailingRow.implicitHeight + 4, 24)
    radius: TrayStyle.rowRadius
    color: row.highlighted ? TrayStyle.hover : "transparent"
    border.width: row.highlighted && TrayStyle.hoverBorder.a > 0 ? 1 : 0
    border.color: TrayStyle.hoverBorder

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: row.activated()
    }

    Row {
        id: lead

        anchors.left: parent.left
        anchors.leftMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        Rectangle {
            visible: row.radio
            anchors.verticalCenter: parent.verticalCenter
            width: 13
            height: 13
            radius: 6.5
            color: TrayStyle.radio.fill
            border.width: 1
            border.color: row.highlighted ? TrayStyle.radio.borderHover : TrayStyle.radio.border

            Rectangle {
                visible: row.checked
                anchors.centerIn: parent
                width: 5
                height: 5
                radius: 2.5
                color: TrayStyle.radio.dot
            }
        }

        TrayIcon {
            visible: row.icon !== ""
            anchors.verticalCenter: parent.verticalCenter
            implicitSize: row.iconSize
            name: row.icon
            tint: row.iconTint
        }
    }

    Column {
        id: labels

        anchors.left: lead.right
        anchors.leftMargin: lead.visibleChildren.length > 0 ? 6 : 0
        anchors.right: trailingRow.left
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter

        Text {
            width: parent.width
            text: row.label
            elide: Text.ElideRight
            color: row.textColor
            font.family: TrayStyle.font
            font.pixelSize: TrayStyle.fontSize
            font.bold: row.bold && !Theme.fontBitmap
            font.underline: row.link && area.containsMouse
        }

        Text {
            visible: row.detail !== ""
            width: parent.width
            text: row.detail
            elide: Text.ElideRight
            color: row.highlighted ? row.textColor : TrayStyle.textMuted
            font.family: TrayStyle.font
            font.pixelSize: Theme.textSize(-1)
        }
    }

    Row {
        id: trailingRow

        anchors.right: parent.right
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6
    }
}
