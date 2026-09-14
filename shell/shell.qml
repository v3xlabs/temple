//@ pragma UseQApplication
import Quickshell
import Quickshell.Hyprland
import "bar"
import "palette"
import "background"
import "notifications"
import "keybinds"

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
        }
    }

    Palette {
        id: palette
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
}
