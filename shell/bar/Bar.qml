import Quickshell
import "../theme"

// One bar per screen, drawn in the style and skin the active theme names.
Scope {
    id: root

    required property ShellScreen screen
    property bool startOpen: false

    signal startRequested

    readonly property string kind: Theme.style + "/" + Theme.skin

    LazyLoader {
        active: root.kind === "xp/drawn"

        XpBar {
            screen: root.screen
            onStartRequested: root.startRequested()
        }
    }

    LazyLoader {
        active: root.kind === "xp/msstyles"

        XpLunaBar {
            screen: root.screen
            startOpen: root.startOpen
            onStartRequested: root.startRequested()
        }
    }

    LazyLoader {
        active: root.kind === "win7/drawn"

        Win7Bar {
            screen: root.screen
            onStartRequested: root.startRequested()
        }
    }

    LazyLoader {
        active: root.kind === "win7/msstyles"

        Win7AeroBar {
            screen: root.screen
            startOpen: root.startOpen
            onStartRequested: root.startRequested()
        }
    }

    // Every macOS skin draws the same bar from its own tokens.
    LazyLoader {
        active: Theme.style === "macos"

        MacosBar {
            screen: root.screen
            startOpen: root.startOpen
            onStartRequested: root.startRequested()
        }
    }

    LazyLoader {
        active: root.kind === "templeos/drawn"

        TempleosBar {
            screen: root.screen
            startOpen: root.startOpen
            onStartRequested: root.startRequested()
        }
    }
}
