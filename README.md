# v3x temple

A desktop built on KDE Plasma 6 and Quickshell, packaged as a NixOS module. It adds a Temple session next to Plasma in the login screen. The Temple session is Plasma with KWin, KWallet, System Settings and the portals, and with the Temple shell in place of plasmashell. The Plasma session stays as it was.

## Layout

- `modules/temple.nix` is the NixOS module. It enables Plasma 6, registers the `temple` session, and renders the kitty config, Temple's global shortcuts and KWin settings, and one directory per theme under `/etc/temple`.
- `modules/luna.nix` downloads XP's `luna.msstyles` at build time and cuts the Luna Blue bitmaps out of it, with transparency from the style's colour key or alpha. `frame/` holds the window frame and caption buttons; `startpanel/` holds the Start menu parts; `dialog/` holds the push buttons, tabs, tab pane, group box, combo box, spin buttons and check boxes. The module exposes them as `/etc/temple/luna`. Microsoft owns these bitmaps, so the repository holds only the URL and hash.
- `modules/timedate.nix` downloads XP's `timedate.cpl` from an XP SP3 install image at build time and takes out its world map, exposed as `/etc/temple/timedate/worldmap.png`. Microsoft owns the bitmap, so the repository holds only the URL and hash.
- `modules/kwin.nix` builds one KWin window decoration and one Alt+Tab switcher per theme from the QML in `modules/kwin/`. The XP theme uses `modules/kwin/decoration-xp`, which assembles the Luna Blue frame and caption buttons from `luna.nix`'s `frame/` bitmaps.
- `shell/start/XpStartMenu.qml` assembles the XP Start menu from the `startpanel/` bitmaps: the user pane, the program and places lists with their separators, the All Programs button and arrow, the log-off pane and its buttons, and the All Programs flyout. It uses the default pane sizes, sizing margins and content margins of `StartPanel.*` and `StartMenu::Toolbar.*` in the style's `NORMALBLUE_INI`. The arrow keys move the selection; Right on All Programs opens the flyout.
- The bar clock opens the clock of its Windows version. Hovering it shows the long date in a tooltip. Under XP, a click opens `shell/clock/XpDateTime.qml`, the Date and Time Properties dialog, assembled from the `frame/` and `dialog/` bitmaps at the positions of `timedate.cpl`'s dialog templates: the Date & Time tab with the month list, year spinner, month grid, analog clock and time field, the Time Zone tab with the zone and the world map, and the Internet Time tab with whether `systemd-timesyncd.service` runs and the first server of `/etc/systemd/timesyncd.conf`. Apply and OK set what changed through `systemctl`, so polkit asks for the password once: a new date or time starts `temple-set-time@<date and time>.service`, which the module defines to stop `systemd-timesyncd.service` and run `timedatectl set-time`, and the Internet Time check box starts or stops `systemd-timesyncd.service`. NixOS keeps unit files read-only, so `timedatectl set-ntp` fails, and a stopped timesyncd starts again at the next boot. Under Windows 7, a click opens `shell/clock/Win7Clock.qml`, the clock flyout: the long date, which returns the calendar to today, a month grid that zooms out to a year and a decade, the analog clock with the time and weekday, and "Change date and time settings...", which opens Plasma's Date & Time settings. The Windows 7 flyouts lay their content on a white sheet inside the glass frame, as Windows 7 did; the `sheet` of the `tray.popup` tokens in `themes/win7-black.nix` draws it.
- `modules/wallpapers.nix` downloads the default wallpapers of Windows XP, Windows 7, macOS Sequoia and macOS Tahoe at build time into `/etc/temple/wallpapers`, for the background picker. Microsoft and Apple own these images, so the repository holds only their URLs and hashes.
- `modules/clippy.nix` downloads Clippy's sprite sheet and animation table from clippy.js into `/etc/temple/clippy`. Under the XP theme, `shell/clippy/Clippy.qml` shows him while [Voxtype](https://github.com/peteonrails/voxtype) works: he listens while it records (and taps his finger once `voxtype-audio-bridge` reports silence), works while it transcribes, and shows Voxtype's notifications in his balloon instead of the normal popup. He reads Voxtype's state from `$XDG_RUNTIME_DIR/voxtype/state`, so Voxtype's `state_file` must stay `"auto"`.
- `themes/` holds the built-in themes: `xp-luna` (Windows XP Luna), `win7-black` (Windows 7 Black, the default), `win7-aero` (Windows 7 Aero), `macos-sequoia` (macOS Sequoia), `macos-tahoe` (macOS Tahoe) and `templeos` (TempleOS). The `themeType` submodule in `modules/temple.nix` defines their shape: a base16 palette, an optional terminal palette, glass, radius, font and window-border tokens, a `style` (`xp`, `win7`, `macos` or `templeos`) that picks the bar, start menu, session dialogs and clock, that style's `bar` tokens, the bar `edge`, and the `tray` and `notifications` tokens that the shared flyouts, tooltips, notification popups and notification centre draw from. `frame`, `lineWidth` and `font.bitmap` cover the macOS glass and the TempleOS text mode. `win7-aero` imports `win7-black` and changes only the colours; both macOS themes take their flyout tokens from `macos-flyouts.nix`. A new theme starts from a copy or an import of a built-in one. The XP and Windows 7 bars use the bitmaps in `shell/bar/assets/`, taken from the original Windows visual styles; the Windows 7 bar lays them over the `bar` tint and opacity. Both macOS themes draw from the `bar` tokens that `shell/macos/Macos.qml` reads, so another macOS release is one more theme with its own tokens. The macOS themes use SF Pro and SF Mono, which the module extracts from Apple's download images. `templeos` uses the 8x8 system font of TempleOS, which `modules/templeos-font.nix` builds from `Kernel/FontStd.HC` of the TempleOS source.
- `shell/` is the Quickshell config. `theme/Theme.qml` reads every theme from `/etc/temple/themes.json` and `Background.qml` reads `/etc/temple/backgrounds.json`. Both hot-reload.
- `shell/osd/Osd.qml` replaces plasmashell's volume and brightness pop-up. It shows when the volume or mute state of the default PipeWire output changes, and when powerdevil reports a change from the brightness keys (its `org.kde.ScreenBrightness` `BrightnessChanged` signal, read through `busctl --user monitor`). It hides 1.5 s after the last change.
- `shell/notifications/Notifications.qml` shows the notification popups. The XP theme draws a balloon. Its tail points at the tray icon of the app that sent the notification (when the status notifier id or title is the same as the notification's app name or desktop entry, ignoring case and separators), else at the clock. The XP bar publishes its tray icons through `shell/tray/TrayIcons.qml`.
- `shell/clipboard/Clipboard.qml` is the clipboard history that Super+V opens, framed like the theme's tray flyouts. Klipper, Plasma's clipboard manager, runs inside plasmashell, which the Temple session does not start. So the shell loads Klipper's history model from plasma-workspace's `org.kde.plasma.private.clipboard` QML module. The model records each copy into `~/.local/share/klipper/history3.sqlite` and reads `klipperrc`, the same files as plain Plasma, so the history and the clipboard settings carry over between the sessions. Klipper's own popup, D-Bus service and shortcuts do not run in the Temple session. Klipper ignores images by default; `/etc/temple/xdg/klipperrc` makes it keep them in the Temple session. That setting is not locked, so an `IgnoreImages` in `~/.config/klipperrc`, which Klipper's settings write under plain Plasma, wins.
- `shell/health/Health.qml` watches the processor and the disks. It warns when the processor averages 98% or more over 10 seconds (and clears under 90%), when a disk has less free space than 20 GB or a tenth of its size, whichever is smaller, and when a disk grows fast enough to be full within 10 minutes (measured over at least 30 seconds, cleared once it would take 30). It checks the processor every 2 seconds from `/proc/stat` and the disks every 10 seconds with `df`, leaving out tmpfs, devtmpfs, ramfs, efivarfs, squashfs and overlay mounts. Each warning sends one notification, from "System Health", when it starts; only the filling warning is critical and stays until dismissed. Under the XP theme Clippy reads the warnings out. While a warning lasts, `shell/health/HealthIcon.qml` shows a warning icon in the bar (`Sys:CPU!` or `Sys:Disk!` under TempleOS); its tooltip names the warnings and a click lists them, each opening System Monitor or the disk in Dolphin. `/etc/temple/xdg/kded5rc` turns off Plasma's own free space notifier in the Temple session, so a low disk warns once.
- `hosts/vm.nix` is the test VM. It autologs the `temple` user into the Temple session.

## Themes

Super+T opens the theme picker. Each highlighted theme is applied to the whole desktop at once: the shell, the KWin window decoration and Alt+Tab switcher, and kitty. Enter keeps the theme. Escape goes back to the theme that was active when the picker opened. `qs -p /etc/temple/shell ipc call theme set xp-luna` does the same from a terminal.

The active theme is the link `~/.local/state/temple/theme`, which points into `/etc/temple/themes/<name>`. The session creates it from `temple.theme` on the first login, and again if the linked theme is removed. `temple-apply-theme <name>` moves the link, has KWin reload its config, and sends SIGUSR1 to kitty so that kitty rereads its config.

The Temple session puts `~/.local/state/temple/theme/xdg` and `/etc/temple/xdg` in front of `XDG_CONFIG_DIRS`, and `/etc/temple/share` in front of `XDG_DATA_DIRS`. KWin finds the theme's window decoration, Alt+Tab switcher and Temple's shortcuts there. The Temple settings are locked in those files, so they win over what plain Plasma keeps in `~/.config`, and Temple writes nothing to `~/.config`. Plain Plasma does not read these directories, so its decoration, switcher, shortcuts and lock screen stay as they were.

A kitty that uses its own config can follow the theme with `include ~/.local/state/temple/theme/kitty.conf` as the last line of that config.

## Use

```
just vm      # build and boot the VM
just build   # build only
just check   # nix flake check
just fmt     # alejandra + qmlformat
```

The VM mounts the host Nix store over virtiofs, so a rebuild only builds the changed store paths and no disk image. Shell edits still need a rebuild and a VM restart. Inside the VM, `systemctl --user restart temple-shell` restarts the shell and `journalctl --user -u temple-shell` prints its errors. `just shell` runs this checkout's shell against the VM's generated config. Stop the running shell first with `systemctl --user stop temple-shell`. KWin hands the window list only to the system's `quickshell`, so run `just shell` with the same nixpkgs as the system.

## Tests

`nix flake check` (or `just check`) runs the VM tests in `tests/`. `nix/checks.nix` registers them, and `tests/common.nix` holds the shared VM node and the Python helpers. Each test boots the VM host in QEMU, so the machine needs KVM. To run one test:

```
nix build -L --no-link 'path:.#checks.x86_64-linux.<name>'
```

| Test | What it asserts |
| --- | --- |
| `sessions` | Plain Plasma runs plasmashell with the user's decoration and has no Temple shell or shortcuts. The Temple session runs the Temple shell and no plasmashell or splash, registers its shortcuts, and uses the theme's KWin decoration. A theme switch moves the decoration and switcher, windows keep a decoration, and `~/.config/kwinrc` gets no Temple settings. This test boots two VMs. |
| `picker-screens` | On three screens, Super+T and the launcher open one theme picker, on the screen of the active window. Arrows preview themes and Escape restores the first one. |
| `pickers` | Scrolling the theme picker previews themes and Enter keeps one. Typing filters the background picker, Enter writes the choice to `~/.local/state/temple/background.path` and the lock screen link, Escape drops a preview, and scrolling picks another wallpaper. |
| `clippy` | Clippy comes on screen while Voxtype records, stays while it transcribes, opens his balloon for Voxtype's notification, and leaves once Voxtype is idle and the balloon times out. |
| `clipboard` | Copies show in the Super+V history in the XP, Windows 7, macOS and TempleOS styles. Escape leaves the clipboard as it was, Enter on an older entry puts that entry back on the clipboard, and typing filters the entries. With no `klipperrc` of the user's own, an image copy is kept, shows a thumbnail, and Enter puts the image back. |
| `health` | Busy loops on every core raise one CPU warning, and another once they stop and start again. A loop disk filled past nine tenths raises a low space warning, and a loop disk written at 2 MB/s raises a filling warning. |

The screenshots the tests take are in the output path of the check.

## Include in a NixOS config

```nix
inputs.temple.url = "github:lucemans/v3x-temple";

# in a host
imports = [inputs.temple.nixosModules.temple];
temple.enable = true;
temple.theme = "xp-luna"; # first-login theme, picked from temple.themes
temple.themes.mine = import ./mine.nix; # added next to the built-in themes
temple.terminal = pkgs.kitty; # opened by Super+Return, Alt+K and the launcher
temple.backgrounds = [./left.png ./right.png]; # default: [shell/bg.png]
temple.bar.monitors = { top = ["DP-5"]; bottom = ["DP-4"]; }; # XP and Windows 7 draw their taskbar at the bottom and no top bar; [] means every screen
temple.activateLinux = { enable = true; monitors = ["DP-4"]; }; # opt-in "Activate Linux" watermark, toggled from a bar icon
temple.keybinds.terminal = {
  key = "Alt+K"; # Plasma notation: Meta, Ctrl, Alt, Shift, then a key
  command = "kitty";
};
```

Pick Temple in SDDM. The Temple session starts the same Plasma services as the Plasma session, apart from plasmashell and the splash screen. Both sessions share one KDE config and one KWallet, so apps such as Chromium and Signal keep their stored secrets in either session.

Temple's shortcuts are two KDE global shortcut components, present only in the Temple session. The shell's own actions (Super, Super+K, Super+/, Super+T, Super+B, Super+V) are the component "Temple shell": the shell registers them for the session only and gets each key press as a D-Bus signal, so text typed right after Super lands in the Start menu. System Settings can rebind them until the next login. The commands are the component "Temple": System Settings lists them under Shortcuts and can rebind them. A `temple.keybinds` entry with the same key as a default below replaces that default. KWin's own shortcuts, such as window tiling, virtual desktops and Print, keep their Plasma settings.

`temple.bar.monitors` names the screens that get a bar, by connector name as `kscreen-doctor -o` prints it. An empty list puts a bar on every screen.

## Keys

| Keys | Action |
| --- | --- |
| Super | Start menu |
| Super+K | Launcher: apps, commands, theme picker |
| Start button | Start menu in the style of the theme: pinned and recent programs, All Programs, folders, and Log off / Shut down behind a confirmation dialog |
| Super+T | Theme picker |
| Super+B | Background picker: `temple.backgrounds`, the images in `~/Pictures/Wallpapers`, and the default wallpapers of Windows XP, Windows 7, macOS Sequoia and macOS Tahoe |
| Super+V | Clipboard history, newest first. Type to filter, arrows to select, Enter to put the selected entry back on the clipboard, Escape to close |
| Super+Return | Terminal (`temple.terminal`) |
| Alt+K | Terminal (`temple.terminal`) |
| Super+/ | Show Temple's keybinds |
| Super+Q | Close window |
| Super+F | Fullscreen |
| Alt+Tab / Alt+Shift+Tab | Window switcher in the style of the theme, with live previews, most recently used first. Release Alt to switch, Escape to cancel |

Plasma's defaults cover the rest, among them Super+L to lock, Super+E for Dolphin, Print for Spectacle, Super+Arrows to tile, Super+PgUp to maximize, Super+Drag to move, and the volume, media and brightness keys.

## Sign-in screen

An XP-style SDDM sign-in screen, off by default.

```nix
inputs.temple.url = "github:lucemans/v3x-temple";

# in a host
imports = [inputs.temple.nixosModules.sddm];
temple.sddm.enable = true;
```

`nixosModules.temple` already imports this module, so with Temple only `temple.sddm.enable = true;` is needed.
