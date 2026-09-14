pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string path: Quickshell.env("TEMPLE_THEME") || "/etc/temple/theme.json"
    property var data: ({})

    readonly property var palette: data.palette ?? ({})
    readonly property color accent: data.accent ?? "#79b8ff"
    readonly property color surface: data.glass?.tint ?? "#14141c"
    readonly property real surfaceOpacity: data.glass?.opacity ?? 0.72
    readonly property color border: data.glass?.border ?? "#ffffff1a"
    readonly property color text: palette.base05 ?? "#d6d6e0"
    readonly property color textMuted: palette.base04 ?? "#8f8fa3"
    readonly property color selection: palette.base02 ?? "#26262f"
    readonly property int radius: data.radius ?? 14
    readonly property string fontSans: data.font?.sans ?? "sans-serif"
    readonly property string fontMono: data.font?.mono ?? "monospace"
    readonly property int fontSize: data.font?.size ?? 13

    FileView {
        path: root.path
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.data = JSON.parse(text())
    }
}
