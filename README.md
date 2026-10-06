# v3x temple

A Wayland desktop built on Hyprland and Quickshell, packaged as a NixOS module.

## Layout

- `modules/temple.nix` is the NixOS module. It enables Hyprland, registers the `temple` session for SDDM, and renders the Hyprland, kitty and hyprlock config plus one directory per theme under `/etc/temple`.
- `themes/` holds the built-in themes: `xp` (Windows XP), `xp-luna` (Windows XP Luna), `win7-black` (Windows 7 Black, the default), `win7-aero` (Windows 7 Aero), `macos-sequoia` (macOS Sequoia), `macos-tahoe` (macOS Tahoe) and `templeos` (TempleOS). The `themeType` submodule in `modules/temple.nix` defines their shape: a base16 palette, an optional terminal palette, glass, radius, font and window-border tokens, a `style` (`xp`, `win7`, `macos` or `templeos`) that picks the bar, start menu and session dialogs, a `skin`, that style's `bar` tokens, the bar `edge`, and the `tray` and `notifications` tokens that the shared flyouts, tooltips, notification popups and notification centre draw from. `frame`, `lineWidth` and `font.bitmap` cover the macOS glass and the TempleOS text mode. `xp-luna` and `win7-aero` import `xp` and `win7-black` and change only the skin and colours; both macOS themes take their flyout tokens from `macos-flyouts.nix`. A new theme starts from a copy or an import of a built-in one. Skin `drawn` paints the bar from the tokens; skin `msstyles` uses the bitmaps in `shell/bar/assets/`, taken from the original Windows visual styles. Skins `sequoia` and `tahoe` are macOS releases; both draw from the `bar` tokens that `shell/macos/Macos.qml` reads, so another release is one more skin with its own tokens. The macOS themes use SF Pro and SF Mono, which the module extracts from Apple's download images. `templeos` uses the 8x8 system font of TempleOS, which `modules/templeos-font.nix` builds from `Kernel/FontStd.HC` of the TempleOS source.
- `shell/` is the Quickshell config. `theme/Theme.qml` reads every theme from `/etc/temple/themes.json` and `Background.qml` reads `/etc/temple/backgrounds.json`. Both hot-reload.
- `hosts/vm.nix` is the test VM. It autologs the `temple` user into the Temple session.

## Themes

Super+T opens the theme picker. Each highlighted theme is applied to the whole desktop at once: the shell, Hyprland borders and blur, kitty, and the lock screen. Enter keeps the theme. Escape goes back to the theme that was active when the picker opened. `qs -p /etc/temple/shell ipc call theme set xp` does the same from a terminal.

The active theme is the link `~/.local/state/temple/theme`, which points into `/etc/temple/themes/<name>`. The session creates it from `temple.theme` on the first login and again if the linked theme is removed. `temple-apply-theme <name>` moves the link, evaluates the theme's `hyprland.lua` in the running Hyprland, and sends SIGUSR1 to kitty so that kitty rereads its config.

A kitty that uses its own config can follow the theme with `include ~/.local/state/temple/theme/kitty.conf` as the last line of that config.

## Use

```
just vm      # build and boot the VM
just build   # build only
just check   # nix flake check
just fmt     # alejandra + qmlformat
```

The VM mounts the host Nix store over virtiofs, so a rebuild only builds the changed store paths and no disk image. Shell edits still need a rebuild and a VM restart. Inside the VM, `qs -p /etc/temple/shell` restarts the shell and prints its errors. Inside a Temple session, `just shell` runs this checkout's shell against the VM's generated config. Stop the running shell first.

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
temple.kwallet.enable = true; # default when Plasma 6 is enabled: Signal, Chromium and other apps share Plasma's KWallet 6
temple.titlebars.exclude = ["chromium(-browser)?" "code" "discord"]; # window classes that draw their own title bar; Temple adds one to every other window
temple.keybinds.terminal = {
  key = "Alt+K"; # Plasma notation: Meta, Ctrl, Alt, Shift, then a key
  command = "kitty";
};
```

Temple registers a wayland session next to Plasma. Pick it in SDDM. The session runs under UWSM, so `graphical-session.target` starts and with it the polkit agent, hypridle, the portals and any other user unit that wants a graphical session.

A `temple.keybinds` entry with the same key as a default below replaces that default.

## Keys

| Keys | Action |
| --- | --- |
| Super+K | Launcher: apps, commands, theme picker |
| Start button | Start menu in the style of the theme: pinned and recent programs, All Programs, folders, and Log off / Shut down behind a confirmation dialog |
| Super+T | Theme picker |
| Super+Return | Terminal (`temple.terminal`) |
| Alt+K | Terminal (`temple.terminal`) |
| Print / Shift+Print | Screenshot a region / every screen to `~/Pictures/Screenshots` and the clipboard |
| Volume, mute, media and brightness keys | wpctl, playerctl, brightnessctl. These also work on the lock screen |
| Super+L | Lock (`temple-lock`) |
| Alt+Tab / Alt+Shift+Tab | Window switcher with live previews, most recently used first. Release Alt to switch, Escape to cancel. Minimized windows come back when picked |
| Click | Focuses the window and brings it to the front |
| Super+E | dolphin |
| Super+/ | Show all keybinds |
| Hold Super / Hold Alt | List the binds that start with that modifier |
| Super+Q | Close window |
| Super+F | Fullscreen |
| Super+Up | Maximize |
| Super+Down | Restore a maximized window, minimize a restored one |
| Super+V | Toggle tiling (windows float by default) |
| Super+Drag / Super+Right-drag | Move / resize with the mouse. Dropping on the top edge maximizes, on a side edge takes that half, in a corner a quarter. Dragging a snapped window away restores its size |
| Super+Left / Super+Right | Move one half-screen that way: left half, right half, then the next screen's left half. Super+Down restores the size from before the snap |
| Super+Shift+Arrows | Send window to the screen in that direction |
| Super+Ctrl+Arrows | Focus |
| Super+Shift+1..9 | Send window to workspace |
| Super+1..9 | Workspace |
| Super+Shift+R | Reload Hyprland config |
| Super+Shift+M | Exit Temple |
