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

ShellRoot {
    Variants {
        model: Quickshell.screens

        Background {
            required property ShellScreen modelData
            screen: modelData
        }
    }

    Variants {
        model: Quickshell.screens

        Bar {
            required property ShellScreen modelData
            screen: modelData
            onStartRequested: palette.toggle()
        }
    }

    Palette {
        id: palette
        onThemesRequested: themePicker.show()
    }

    ThemePicker {
        id: themePicker
    }

    Keybinds {
        id: keybinds
    }

    Notifications {}

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
