import Quickshell
import "../theme"

// The start button's menu. The XP and Win7 themes draw their own start menu;
// the other themes open the launcher.
Scope {
    id: root

    signal launcherRequested
    signal themesRequested

    function toggle(screen: ShellScreen) {
        const menu = Theme.style === "xp" ? xp.item : Theme.style === "win7" ? win7.item : null;
        if (menu)
            menu.toggle(screen);
        else
            launcherRequested();
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
}
