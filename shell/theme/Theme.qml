pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var themes: ({})
    property string fallback: ""
    property string name: ""
    // Bar tokens of the last theme seen per style. A bar keeps reading its own
    // style's tokens while its loader tears it down after a style switch.
    property var barTokens: ({})
    // The linked theme was removed by a rebuild; it is replaced by the default once the themes load.
    property bool linkBroken: false

    function relink() {
        if (!linkBroken || !(fallback in themes))
            return;
        linkBroken = false;
        set(fallback);
    }

    readonly property var names: Object.keys(themes)
    readonly property var data: themes[name] ?? ({})
    readonly property bool ready: name in themes
    readonly property string barEdge: data.edge ?? "bottom"
    readonly property string frame: data.frame ?? "plain"
    readonly property int lineWidth: data.lineWidth ?? 1
    readonly property var tray: data.tray ?? ({})
    readonly property var notifications: data.notifications ?? ({})

    readonly property string label: data.label ?? name
    readonly property string style: data.style ?? ""
    readonly property var palette: data.palette ?? ({})
    readonly property color accent: data.accent ?? "#79b8ff"
    readonly property color surface: data.glass?.tint ?? "#14141c"
    readonly property real surfaceOpacity: data.glass?.opacity ?? 0.72
    readonly property real panelOpacity: Math.min(surfaceOpacity + 0.15, 1)
    readonly property color border: data.glass?.border ?? "#1affffff"
    // KWin blurs behind a surface only where the shell asks it to.
    readonly property bool blur: (data.glass?.blur ?? 0) > 0
    readonly property color text: palette.base05 ?? "#d6d6e0"
    readonly property color textMuted: palette.base04 ?? "#8f8fa3"
    readonly property color selection: palette.base02 ?? "#26262f"
    readonly property int radius: data.radius ?? 14
    readonly property string fontSans: data.font?.sans ?? "sans-serif"
    readonly property string fontMono: data.font?.mono ?? "monospace"
    readonly property int fontSize: data.font?.size ?? 13
    readonly property bool fontBitmap: data.font?.bitmap ?? false

    // A bitmap font stays sharp only at its own size.
    function textSize(step: int): int {
        return fontBitmap ? fontSize : fontSize + step;
    }

    // Recolors the shell at once and syncs KWin, Qt apps and kitty shortly after.
    function set(next: string): bool {
        if (!(next in themes))
            return false;
        select(next);
        applyDelay.restart();
        return true;
    }

    function select(next: string, from = themes) {
        const theme = from[next];
        barTokens = Object.assign({}, barTokens, {
            [theme.style]: theme.bar ?? {}
        });
        name = next;
    }

    // Themes write #RRGGBBAA. QML reads 8 digits as #AARRGGBB.
    function qmlColors(value) {
        if (typeof value === "string" && /^#[0-9a-fA-F]{8}$/.test(value))
            return "#" + value.slice(7) + value.slice(1, 7);
        if (Array.isArray(value))
            return value.map(qmlColors);
        if (value !== null && typeof value === "object") {
            const converted = {};
            for (const key in value)
                converted[key] = qmlColors(value[key]);
            return converted;
        }
        return value;
    }

    FileView {
        path: Quickshell.env("TEMPLE_THEMES") || "/etc/temple/themes.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const index = JSON.parse(text());
            const themes = root.qmlColors(index.themes);
            root.fallback = index.default;
            // Tokens first: a bar loads the moment `themes` names its style.
            root.select(root.name in themes ? root.name : root.fallback, themes);
            root.themes = themes;
            root.relink();
        }
    }

    // The session links ~/.local/state/temple/theme to the active theme directory.
    FileView {
        path: Quickshell.env("HOME") + "/.local/state/temple/theme/theme.json"
        onLoaded: {
            const active = JSON.parse(text()).name;
            if (Object.keys(root.themes).length === 0)
                root.name = active;
            else if (active in root.themes)
                root.select(active);
        }
        onLoadFailed: {
            root.linkBroken = true;
            root.relink();
        }
    }

    Timer {
        id: applyDelay
        // Each apply reconfigures KWin; browsing quickly should only apply once.
        interval: 250
        onTriggered: {
            if (apply.running)
                apply.pending = true;
            else
                apply.running = true;
        }
    }

    Process {
        id: apply

        property bool pending: false

        command: ["temple-apply-theme", root.name]
        onExited: {
            if (pending) {
                pending = false;
                running = true;
            }
        }
    }

    IpcHandler {
        target: "theme"

        function set(name: string): string {
            return root.set(name) ? root.name : `unknown theme ${name}, expected one of ${root.names.join(", ")}`;
        }
        function get(): string {
            return root.name;
        }
        function list(): string {
            return root.names.join("\n");
        }
    }
}
