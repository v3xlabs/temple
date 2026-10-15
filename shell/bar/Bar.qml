import Quickshell
import "../theme"

// One bar per screen, drawn in the style the active theme names.
Scope {
    id: root

    required property ShellScreen screen
    property bool startOpen: false

    signal startRequested

    LazyLoader {
        active: Theme.style === "xp"

        XpBar {
            screen: root.screen
            startOpen: root.startOpen
            onStartRequested: root.startRequested()
        }
    }

    LazyLoader {
        active: Theme.style === "win7"

        Win7Bar {
            screen: root.screen
            startOpen: root.startOpen
            onStartRequested: root.startRequested()
        }
    }

    // Every macOS release draws the same bar from its own tokens.
    LazyLoader {
        active: Theme.style === "macos"

        MacosBar {
            screen: root.screen
            startOpen: root.startOpen
            onStartRequested: root.startRequested()
        }
    }

    LazyLoader {
        active: Theme.style === "templeos"

        TempleosBar {
            screen: root.screen
            startOpen: root.startOpen
            onStartRequested: root.startRequested()
        }
    }
}
