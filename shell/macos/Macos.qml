pragma Singleton
import QtQuick
import Quickshell
import "../theme"

// The `bar` tokens of the last macOS theme, typed. Each macOS release is a
// skin that differs only in these tokens.
Singleton {
    readonly property var tokens: Theme.barTokens.macos

    readonly property int height: tokens.height
    readonly property color tint: tokens.tint
    readonly property real opacity: tokens.opacity
    readonly property color text: tokens.text
    readonly property color hover: tokens.hover
    readonly property int itemRadius: tokens.itemRadius

    readonly property color panel: tokens.panel
    readonly property real panelOpacity: tokens.panelOpacity
    readonly property color panelText: tokens.panelText
    readonly property color panelMuted: tokens.panelMuted
    readonly property color edge: tokens.edge
    readonly property color specular: tokens.specular
    // Strength of the light falling across the top of a glass surface.
    readonly property real sheen: tokens.sheen
    readonly property color separator: tokens.separator
    readonly property color selection: tokens.selection
    readonly property color selectionText: tokens.selectionText
    readonly property int selectionRadius: tokens.selectionRadius

    readonly property int menuRadius: tokens.menuRadius
    readonly property int panelRadius: tokens.panelRadius
    readonly property int bannerRadius: tokens.bannerRadius
    readonly property int dialogRadius: tokens.dialogRadius

    readonly property string font: Theme.fontSans
    readonly property int fontSize: Theme.fontSize
    readonly property string appleLogo: "\uf8ff"
}
