import Quickshell
import "../theme"
import "../windows"

// The start button's menu and the session confirmations, drawn in the
// style of the active theme.
Scope {
    id: root

    signal launcherRequested
    signal themesRequested

    readonly property var menu: [xp, win7, macos, templeos].find(loader => loader.active)?.item ?? null
    readonly property ShellScreen openScreen: menu?.open ? menu.screen : null

    function toggle(screen: ShellScreen) {
        menu?.toggle(screen);
    }

    // action: "shutdown", "reboot", "logout" or "suspend".
    function confirm(action: string) {
        menu?.confirmOn(Windows.focusedScreen, action);
    }

    LazyLoader {
        id: xp

        active: Theme.style === "xp"

        XpStartMenu {
            onLauncherRequested: root.launcherRequested()
            onThemesRequested: root.themesRequested()
        }
    }

    LazyLoader {
        id: win7

        active: Theme.style === "win7"

        Win7StartMenu {
            onLauncherRequested: root.launcherRequested()
            onThemesRequested: root.themesRequested()
        }
    }

    LazyLoader {
        id: macos

        active: Theme.style === "macos"

        MacosMenu {
            onLauncherRequested: root.launcherRequested()
            onThemesRequested: root.themesRequested()
        }
    }

    LazyLoader {
        id: templeos

        active: Theme.style === "templeos"

        TempleosMenu {
            onLauncherRequested: root.launcherRequested()
            onThemesRequested: root.themesRequested()
        }
    }
}
