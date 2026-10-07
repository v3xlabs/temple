# v3x temple

A desktop built on KDE Plasma 6 and Quickshell, packaged as a NixOS module. Plasma runs as it does on any NixOS machine, with KWin, KWallet, System Settings and the portals; the Temple shell takes the place of plasmashell.

## Layout

- `modules/temple.nix` is the NixOS module. It enables Plasma 6, swaps plasmashell for the Temple shell, installs Temple's global shortcuts, and renders the kitty config plus one directory per theme under `/etc/temple`.
- `modules/kwin.nix` builds one KWin window decoration and one Alt+Tab switcher per theme from the QML in `modules/kwin/`.
- `themes/` holds the built-in themes: `xp` (Windows XP), `xp-luna` (Windows XP Luna), `win7-black` (Windows 7 Black, the default), `win7-aero` (Windows 7 Aero), `macos-sequoia` (macOS Sequoia), `macos-tahoe` (macOS Tahoe) and `templeos` (TempleOS). The `themeType` submodule in `modules/temple.nix` defines their shape: a base16 palette, an optional terminal palette, glass, radius, font and window-border tokens, a `style` (`xp`, `win7`, `macos` or `templeos`) that picks the bar, start menu and session dialogs, a `skin`, that style's `bar` tokens, the bar `edge`, and the `tray` and `notifications` tokens that the shared flyouts, tooltips, notification popups and notification centre draw from. `frame`, `lineWidth` and `font.bitmap` cover the macOS glass and the TempleOS text mode. `xp-luna` and `win7-aero` import `xp` and `win7-black` and change only the skin and colours; both macOS themes take their flyout tokens from `macos-flyouts.nix`. A new theme starts from a copy or an import of a built-in one. Skin `drawn` paints the bar from the tokens; skin `msstyles` uses the bitmaps in `shell/bar/assets/`, taken from the original Windows visual styles. Skins `sequoia` and `tahoe` are macOS releases; both draw from the `bar` tokens that `shell/macos/Macos.qml` reads, so another release is one more skin with its own tokens. The macOS themes use SF Pro and SF Mono, which the module extracts from Apple's download images. `templeos` uses the 8x8 system font of TempleOS, which `modules/templeos-font.nix` builds from `Kernel/FontStd.HC` of the TempleOS source.
- `shell/` is the Quickshell config. `theme/Theme.qml` reads every theme from `/etc/temple/themes.json` and `Background.qml` reads `/etc/temple/backgrounds.json`. Both hot-reload.
- `hosts/vm.nix` is the test VM. It autologs the `temple` user into Plasma.

## Themes

Super+T opens the theme picker. Each highlighted theme is applied to the whole desktop at once: the shell, the KWin window decoration and Alt+Tab switcher, and kitty. Enter keeps the theme. Escape goes back to the theme that was active when the picker opened. `qs -p /etc/temple/shell ipc call theme set xp` does the same from a terminal.

The active theme is the link `~/.local/state/temple/theme`, which points into `/etc/temple/themes/<name>`. `temple-init` creates it from `temple.theme` before KWin starts on the first login, and again if the linked theme is removed. `temple-apply-theme <name>` moves the link, points KWin's decoration and switcher at the theme's `temple-<name>` packages in `kwinrc`, has KWin reload its config, and sends SIGUSR1 to kitty so that kitty rereads its config.

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

Logging in to Plasma starts Temple. The Plasma session starts the same services as without Temple, apart from plasmashell and the splash screen, so KWallet, the polkit agent, power management and the portals behave as they do in a plain Plasma session. Apps that use KWallet, such as Chromium and Signal, keep their stored secrets.

Temple's shortcuts are a KDE global shortcut component named Temple. System Settings lists them under Shortcuts and can rebind them. A `temple.keybinds` entry with the same key as a default below replaces that default. KWin's own shortcuts, such as window tiling, virtual desktops and Print, keep their Plasma defaults and are configured in System Settings.

## Keys

| Keys | Action |
| --- | --- |
| Super | Start menu |
| Super+K | Launcher: apps, commands, theme picker |
| Start button | Start menu in the style of the theme: pinned and recent programs, All Programs, folders, and Log off / Shut down behind a confirmation dialog |
| Super+T | Theme picker |
| Super+B | Background picker |
| Super+Return | Terminal (`temple.terminal`) |
| Alt+K | Terminal (`temple.terminal`) |
| Super+/ | Show Temple's keybinds |
| Super+Q | Close window |
| Super+F | Fullscreen |
| Alt+Tab / Alt+Shift+Tab | Window switcher in the style of the theme, with live previews, most recently used first. Release Alt to switch, Escape to cancel |

Plasma's defaults cover the rest, among them Super+L to lock, Super+E for Dolphin, Print for Spectacle, Super+Arrows to tile, Super+PgUp to maximize, Super+Drag to move, and the volume, media and brightness keys.
