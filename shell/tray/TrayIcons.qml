pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Services.SystemTray

// The status notifier icons in the bars, so a balloon can point at the icon of the app that sent it.
Singleton {
    id: root

    // Entries of {screen, item, sni}.
    property var icons: []

    function add(screen: ShellScreen, item: Item, sni: SystemTrayItem) {
        root.icons = [...root.icons,
            {
                screen,
                item,
                sni
            }
        ];
    }

    function remove(item: Item) {
        root.icons = root.icons.filter(icon => icon.item !== item);
    }

    function key(name: string): string {
        return name.toLowerCase().replace(/[^a-z0-9]/g, "");
    }

    // The screen x of the icon centre, or -1 when the sender has no icon on that screen.
    // Apps usually give their status notifier the id or title that they give their notifications as app name or desktop entry,
    // sometimes with other case or separators ("TelegramDesktop" and "Telegram Desktop").
    function centre(screen: ShellScreen, notification: Notification): real {
        const names = [notification.appName, notification.desktopEntry].map(name => root.key(name)).filter(name => name !== "");
        const icon = root.icons.find(icon => icon.screen === screen && [icon.sni.id, icon.sni.title].some(name => names.includes(root.key(name))));
        // The bars span the full screen width, so a window x is a screen x.
        return icon ? icon.item.mapToItem(null, icon.item.width / 2, 0).x : -1;
    }
}
