//@ pragma UseQApplication
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "bar"
import "palette"
import "background"
import "notifications"
import "keybinds"
import "themes"
import "theme"
import "config"
import "activate"
import "switcher"
import "start"

ShellRoot {
    id: shell

    readonly property var barScreens: Config.barMonitors[Theme.barEdge] ?? []
    readonly property var watermarkScreens: Config.activateLinuxMonitors

    Variants {
        model: Quickshell.screens

        Background {
            required property ShellScreen modelData
            screen: modelData
        }
    }

    Variants {
        model: Quickshell.screens.filter(screen => shell.barScreens.length === 0 || shell.barScreens.includes(screen.name))

        Bar {
            required property ShellScreen modelData
            screen: modelData
            startOpen: startMenu.openScreen === modelData
            onStartRequested: startMenu.toggle(modelData)
        }
    }

    Variants {
        model: Quickshell.screens.filter(screen => shell.watermarkScreens.length === 0 || shell.watermarkScreens.includes(screen.name))

        Watermark {
            required property ShellScreen modelData
            screen: modelData
        }
    }

    StartMenu {
        id: startMenu
        onLauncherRequested: palette.toggle()
        onThemesRequested: themePicker.show()
    }

    Palette {
        id: palette
        onThemesRequested: themePicker.show()
        onBackgroundsRequested: backgroundPicker.toggle()
        onSessionRequested: action => startMenu.confirm(action)
    }

    BackgroundPicker {
        id: backgroundPicker
    }

    ThemePicker {
        id: themePicker
    }

    Keybinds {
        id: keybinds
    }

    KeyHint {
        id: keyHint
        keybinds: keybinds.keybinds
    }

    // Popups read theme tokens from their first binding.
    LazyLoader {
        active: Theme.ready

        Notifications {}
    }

    GlobalShortcut {
        appid: "temple"
        name: "palette"
        description: "Toggle the command palette"
        onPressed: palette.toggle()
    }

    GlobalShortcut {
        appid: "temple"
        name: "keybinds"
        description: "Toggle the keybind overview"
        onPressed: keybinds.toggle()
    }

    GlobalShortcut {
        appid: "temple"
        name: "themes"
        description: "Toggle the theme picker"
        onPressed: themePicker.toggle()
    }

    GlobalShortcut {
        appid: "temple"
        name: "backgrounds"
        description: "Toggle the background picker"
        onPressed: backgroundPicker.toggle()
    }

    GlobalShortcut {
        appid: "temple"
        name: "hint-super"
        description: "List Super binds while Super is held"
        onPressed: keyHint.hold("Super")
    }

    GlobalShortcut {
        appid: "temple"
        name: "released-super"
        description: "Super came up"
        onPressed: keyHint.release()
    }

    GlobalShortcut {
        appid: "temple"
        name: "released-alt"
        description: "Alt came up"
        onPressed: {
            keyHint.release();
            switcher.commit();
        }
    }

    GlobalShortcut {
        appid: "temple"
        name: "hint-alt"
        description: "List Alt binds while Alt is held"
        onPressed: keyHint.hold("Alt")
    }

    Switcher {
        id: switcher
    }

    GlobalShortcut {
        appid: "temple"
        name: "switcher-next"
        description: "Alt+Tab window switcher, next window"
        onPressed: switcher.step(1)
    }

    GlobalShortcut {
        appid: "temple"
        name: "switcher-previous"
        description: "Alt+Tab window switcher, previous window"
        onPressed: switcher.step(-1)
    }

    IpcHandler {
        target: "shell"

        function reload(): void {
            Quickshell.reload(true);
        }
        function togglePalette(): void {
            palette.toggle();
        }
        function toggleThemes(): void {
            themePicker.toggle();
        }
    }
}
