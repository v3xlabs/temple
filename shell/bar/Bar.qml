import Quickshell
import "../theme"

// One bar per screen, drawn in the style the active theme names.
Scope {
    id: root

    required property ShellScreen screen

    signal startRequested

    LazyLoader {
        active: Theme.style === "temple"

        TempleBar {
            screen: root.screen
            onStartRequested: root.startRequested()
        }
    }

    LazyLoader {
        active: Theme.style === "xp"

        XpBar {
            screen: root.screen
            onStartRequested: root.startRequested()
        }
    }

    LazyLoader {
        active: Theme.style === "win7"

        Win7Bar {
            screen: root.screen
            onStartRequested: root.startRequested()
        }
    }
}
