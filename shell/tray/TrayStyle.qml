pragma Singleton
import QtQuick
import Quickshell
import "../theme"

// The `tray` tokens of the active theme, shared by the tray flyouts.
Singleton {
    readonly property var tokens: Theme.tray

    // The flyouts open away from the bar.
    readonly property bool opensDown: Theme.barEdge === "top"

    readonly property color text: tokens.text
    readonly property color textMuted: tokens.textMuted
    readonly property color hover: tokens.hover
    readonly property color hoverBorder: tokens.hoverBorder
    readonly property color hoverText: tokens.hoverText
    readonly property color link: tokens.link
    readonly property color separator: tokens.separator
    readonly property color accent: tokens.accent
    readonly property int rowRadius: tokens.rowRadius

    readonly property color iconTint: tokens.iconTint
    readonly property color hoverIconTint: tokens.hoverIconTint
    readonly property color barIconTint: tokens.barIconTint
    readonly property color barHighlight: tokens.barHighlight
    readonly property bool barLabels: tokens.barLabels

    readonly property var popup: tokens.popup
    readonly property var tip: tokens.tip
    readonly property var button: tokens.button
    readonly property var radio: tokens.radio
    readonly property var network: tokens.network
    readonly property var volume: tokens.volume

    readonly property string font: Theme.fontSans
    readonly property int fontSize: Theme.fontSize
}
