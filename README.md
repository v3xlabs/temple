# v3x temple

A Wayland desktop built on Hyprland and Quickshell, packaged as a NixOS module.

## Layout

- `modules/temple.nix` is the NixOS module. It enables Hyprland, registers the `temple` session for SDDM, and renders theme, Hyprland, and kitty config under `/etc/temple`.
- `themes/` holds theme attrsets. Each one is a base16 palette plus glass, radius, and font tokens.
- `shell/` is the Quickshell config. `Theme.qml` reads `/etc/temple/theme.json` and `Background.qml` reads `/etc/temple/backgrounds.json`. Both hot-reload.
- `hosts/vm.nix` is the test VM. It autologs the `temple` user into the Temple session.

## Use

```
just vm      # build and boot the VM
just build   # build only
just check   # nix flake check
just fmt     # alejandra + qmlformat
```

The VM mounts the host Nix store over virtiofs, so a rebuild only builds the changed store paths and no disk image. Shell edits still need a rebuild and a VM restart. Inside the VM, `qs -p /etc/temple/shell` restarts the shell and prints its errors.

## Include in a NixOS config

```nix
inputs.temple.url = "github:lucemans/v3x-temple";

# in a host
imports = [inputs.temple.nixosModules.temple];
temple.enable = true;
temple.theme = inputs.temple.themes.light;
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
| Super+K | Command palette |
| Super+Return | kitty |
| Alt+K | kitty |
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
