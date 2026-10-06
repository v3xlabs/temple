# v3x temple

A Wayland desktop built on Hyprland and Quickshell, packaged as a NixOS module.

## Layout

- `modules/temple.nix` is the NixOS module. It enables Hyprland, registers the `temple` session for SDDM, and renders the Hyprland, kitty and hyprlock config plus one directory per theme under `/etc/temple`.
- `themes/` holds the built-in themes. The `themeType` submodule in `modules/temple.nix` defines their shape: a base16 palette, an optional terminal palette, glass, radius, font and window-border tokens, a bar `style` (`temple`, `xp` or `win7`) and that style's `bar` tokens.
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
| Super+T | Theme picker |
| Super+Return | Terminal (`temple.terminal`) |
| Alt+K | Terminal (`temple.terminal`) |
| Print / Shift+Print | Screenshot a region / every screen to `~/Pictures/Screenshots` and the clipboard |
| Volume, mute, media and brightness keys | wpctl, playerctl, brightnessctl. These also work on the lock screen |
| Super+L | Lock (`temple-lock`) |
| Alt+Tab / Alt+Shift+Tab | Next / previous window |
| Super+E | dolphin |
| Super+/ | Show all keybinds |
| Super+Q | Close window |
| Super+F | Fullscreen |
| Super+Up / Super+Down | Maximize / restore |
| Super+V | Toggle floating |
| Super+Drag / Super+Right-drag | Move / resize with the mouse |
| Super+Left / Super+Right | Move window left / right, onto the next monitor at the edge |
| Super+Shift+Left / Super+Shift+Right | Send window to the previous / next monitor |
| Super+Shift+Up / Super+Shift+Down | Move window up / down |
| Super+Ctrl+Arrows | Focus |
| Super+Shift+1..9 | Send window to workspace |
| Super+1..9 | Workspace |
| Super+Shift+R | Reload Hyprland config |
| Super+Shift+M | Exit Temple |
