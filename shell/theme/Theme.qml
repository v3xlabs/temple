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

    readonly property var names: Object.keys(themes)
    readonly property var data: themes[name] ?? ({})

    readonly property string label: data.label ?? name
    readonly property string style: data.style ?? "temple"
    readonly property string variant: data.variant ?? "dark"
    readonly property var palette: data.palette ?? ({})
    readonly property color accent: data.accent ?? "#79b8ff"
    readonly property color surface: data.glass?.tint ?? "#14141c"
    readonly property real surfaceOpacity: data.glass?.opacity ?? 0.72
    readonly property real panelOpacity: Math.min(surfaceOpacity + 0.15, 1)
    readonly property color border: data.glass?.border ?? "#1affffff"
    readonly property color text: palette.base05 ?? "#d6d6e0"
    readonly property color textMuted: palette.base04 ?? "#8f8fa3"
    readonly property color selection: palette.base02 ?? "#26262f"
    readonly property int radius: data.radius ?? 14
    readonly property string fontSans: data.font?.sans ?? "sans-serif"
    readonly property string fontMono: data.font?.mono ?? "monospace"
    readonly property int fontSize: data.font?.size ?? 13

    // Recolors the shell at once and syncs Hyprland, kitty and hyprlock shortly after.
    function set(next: string): bool {
        if (!(next in themes))
            return false;
        select(next);
        applyDelay.restart();
        return true;
    }

    function select(next: string) {
        const theme = themes[next];
        barTokens = Object.assign({}, barTokens, {
            [theme.style]: theme.bar ?? {}
        });
        name = next;
    }

    // Themes write #RRGGBBAA like Hyprland. QML reads 8 digits as #AARRGGBB.
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
            root.themes = root.qmlColors(index.themes);
            root.fallback = index.default;
            root.select(root.name in root.themes ? root.name : root.fallback);
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
    }

    Timer {
        id: applyDelay
        interval: 120
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
