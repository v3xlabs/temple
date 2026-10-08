//@ pragma UseQApplication
import Quickshell
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
import "start"
import "windows"
import "clippy"
import "osd"

ShellRoot {
    id: shell

    readonly property var barScreens: Config.barMonitors[Theme.barEdge] ?? []
    readonly property var watermarkScreens: Config.activateLinuxMonitors

    function hasBar(screen: ShellScreen): bool {
        return barScreens.length === 0 || barScreens.includes(screen.name);
    }

    Variants {
        model: Quickshell.screens

        Background {
            required property ShellScreen modelData
            screen: modelData
        }
    }

    Variants {
        model: Quickshell.screens.filter(screen => shell.hasBar(screen))

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

    // Popups read theme tokens from their first binding.
    LazyLoader {
        active: Theme.ready

        Notifications {}
    }

    LazyLoader {
        active: Theme.ready

        Osd {}
    }

    LazyLoader {
        active: Theme.ready && Theme.style === "xp"

        Clippy {}
    }

    // KDE global shortcuts reach the shell through these; see the kglobalaccel
    // component the NixOS module installs.
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
        function toggleBackgrounds(): void {
            backgroundPicker.toggle();
        }
        function toggleKeybinds(): void {
            keybinds.toggle();
        }
        function toggleStart(): void {
            const focused = Windows.focusedScreen;
            startMenu.toggle(shell.hasBar(focused) ? focused : Quickshell.screens.find(screen => shell.hasBar(screen)));
        }
    }
}
