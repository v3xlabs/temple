# v3x temple

A desktop built on KDE Plasma 6 and Quickshell, packaged as a NixOS module. It adds a Temple session next to Plasma in the login screen. The Temple session is Plasma with KWin, KWallet, System Settings and the portals, and with the Temple shell in place of plasmashell. The Plasma session stays as it was.

## Layout

- `modules/temple.nix` is the NixOS module. It enables Plasma 6, registers the `temple` session, and renders the kitty config, Temple's global shortcuts and KWin settings, and one directory per theme under `/etc/temple`.
- `modules/kwin.nix` builds one KWin window decoration and one Alt+Tab switcher per theme from the QML in `modules/kwin/`. The XP themes use `modules/kwin/decoration-xp`, which assembles the Luna Blue frame and caption buttons from the bitmaps in XP's `luna.msstyles`; the build downloads that file and cuts the bitmaps out of it.
- `modules/wallpapers.nix` downloads the default wallpapers of Windows XP, Windows 7, macOS Sequoia and macOS Tahoe at build time into `/etc/temple/wallpapers`, for the background picker. Microsoft and Apple own these images, so the repository holds only their URLs and hashes.
- `themes/` holds the built-in themes: `xp` (Windows XP), `xp-luna` (Windows XP Luna), `win7-black` (Windows 7 Black, the default), `win7-aero` (Windows 7 Aero), `macos-sequoia` (macOS Sequoia), `macos-tahoe` (macOS Tahoe) and `templeos` (TempleOS). The `themeType` submodule in `modules/temple.nix` defines their shape: a base16 palette, an optional terminal palette, glass, radius, font and window-border tokens, a `style` (`xp`, `win7`, `macos` or `templeos`) that picks the bar, start menu and session dialogs, a `skin`, that style's `bar` tokens, the bar `edge`, and the `tray` and `notifications` tokens that the shared flyouts, tooltips, notification popups and notification centre draw from. `frame`, `lineWidth` and `font.bitmap` cover the macOS glass and the TempleOS text mode. `xp-luna` and `win7-aero` import `xp` and `win7-black` and change only the skin and colours; both macOS themes take their flyout tokens from `macos-flyouts.nix`. A new theme starts from a copy or an import of a built-in one. Skin `drawn` paints the bar from the tokens; skin `msstyles` uses the bitmaps in `shell/bar/assets/`, taken from the original Windows visual styles. Skins `sequoia` and `tahoe` are macOS releases; both draw from the `bar` tokens that `shell/macos/Macos.qml` reads, so another release is one more skin with its own tokens. The macOS themes use SF Pro and SF Mono, which the module extracts from Apple's download images. `templeos` uses the 8x8 system font of TempleOS, which `modules/templeos-font.nix` builds from `Kernel/FontStd.HC` of the TempleOS source.
- `shell/` is the Quickshell config. `theme/Theme.qml` reads every theme from `/etc/temple/themes.json` and `Background.qml` reads `/etc/temple/backgrounds.json`. Both hot-reload.
- `hosts/vm.nix` is the test VM. It autologs the `temple` user into the Temple session.

## Themes

Super+T opens the theme picker. Each highlighted theme is applied to the whole desktop at once: the shell, the KWin window decoration and Alt+Tab switcher, and kitty. Enter keeps the theme. Escape goes back to the theme that was active when the picker opened. `qs -p /etc/temple/shell ipc call theme set xp` does the same from a terminal.

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

## Include in a NixOS config

```nix
inputs.temple.url = "github:lucemans/v3x-temple";

# in a host
imports = [inputs.temple.nixosModules.temple];
temple.enable = true;
temple.theme = "xp"; # first-login theme, picked from temple.themes
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

Temple's shortcuts are a KDE global shortcut component named Temple, present only in the Temple session. System Settings lists them under Shortcuts and can rebind them. A `temple.keybinds` entry with the same key as a default below replaces that default. KWin's own shortcuts, such as window tiling, virtual desktops and Print, keep their Plasma settings.

`temple.bar.monitors` names the screens that get a bar, by connector name as `kscreen-doctor -o` prints it. An empty list puts a bar on every screen.

## Keys

| Keys | Action |
| --- | --- |
| Super | Start menu |
| Super+K | Launcher: apps, commands, theme picker |
| Start button | Start menu in the style of the theme: pinned and recent programs, All Programs, folders, and Log off / Shut down behind a confirmation dialog |
| Super+T | Theme picker |
| Super+B | Background picker: `temple.backgrounds`, the images in `~/Pictures/Wallpapers`, and the default wallpapers of Windows XP, Windows 7, macOS Sequoia and macOS Tahoe |
| Super+Return | Terminal (`temple.terminal`) |
| Alt+K | Terminal (`temple.terminal`) |
| Super+/ | Show Temple's keybinds |
| Super+Q | Close window |
| Super+F | Fullscreen |
| Alt+Tab / Alt+Shift+Tab | Window switcher in the style of the theme, with live previews, most recently used first. Release Alt to switch, Escape to cancel |

Plasma's defaults cover the rest, among them Super+L to lock, Super+E for Dolphin, Print for Spectacle, Super+Arrows to tile, Super+PgUp to maximize, Super+Drag to move, and the volume, media and brightness keys.
