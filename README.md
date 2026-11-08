<h1 style="vertical-align: middle;">
<img src="./docs/public/logo.svg" align="left" height="32">
<span align="left">V3X Temple</span>
<a href="https://0rwx.com" target="_blank" align="right">
<picture>
<source srcset="https://0rwx.com/static/AI-X-dark.svg" media="(prefers-color-scheme: dark)">
<img src="https://0rwx.com/static/AI-X-light.svg" alt="AI:X" width="auto" height="32" align="right">
</picture>
</a>
</h1>

> _[Terry Davis](https://templeos.org/) paved the way,<br />
> and [Omarchy](https://omarchy.org/) came out to play,<br />
> The llm had a good day,<br />
> but [Nix](https://nixos.org/) is now to whom we pray._

Welcome to our temple, a KDE Plasma 6 / Quickshell everything-and-then-some desktop environment packed as a NixOS module.

For those on plasma who whished they could experience linux with the cutting edge of windows XP.

## Usage

```nix
# add it to your flake inputs
inputs.temple.url = "github:lucemans/v3x-temple";

# import it
imports = [inputs.temple.nixosModules.temple];

temple = {
  enable = true;
  # set a default theme if you please
  temple.theme = "xp-luna";
  # add your own
  temple.themes.mine = import ./mine.nix;
  # hook in your terminal
  temple.terminal = pkgs.kitty;
  # add backgrounds
  temple.backgrounds = [./left.png ./right.png];
  # Adjust taskbar & topbar
  temple.bar.monitors = { top = ["DP-5"]; bottom = ["DP-4"]; };
  # Adjust activate-linux
  temple.activateLinux = { enable = true; monitors = ["DP-4"]; };
  # Add your own keybinds
  temple.keybinds.terminal = {
    # Plasma notation (Meta, Ctrl, Alt, Shift)
    key = "Alt+K";
    command = "kitty";
  };
}
```


### Sign-in screen (SDDM)

An XP-style SDDM sign-in screen, off by default.

```nix
inputs.temple.url = "github:lucemans/v3x-temple";

imports = [inputs.temple.nixosModules.sddm];
temple.sddm.enable = true;
```

## Default Keybinds

| Keys                    | Action                                                                                                                                        |
| ----------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| Super                   | Start menu                                                                                                                                    |
| Super+K                 | Launcher: apps, commands, theme picker                                                                                                        |
| Start button            | Start menu in the style of the theme: pinned and recent programs, All Programs, folders, and Log off / Shut down behind a confirmation dialog |
| Super+T                 | Theme picker                                                                                                                                  |
| Super+B                 | Background picker                                                                                                                             |
| Super+V                 | Clipboard history                                                                                                                             |
| Super+Return            | Terminal (`temple.terminal`)                                                                                                                  |
| Alt+K                   | Terminal (`temple.terminal`)                                                                                                                  |
| Super+/                 | Show Temple's keybinds                                                                                                                        |
| Super+Q                 | Close window                                                                                                                                  |
| Super+F                 | Fullscreen                                                                                                                                    |
| Alt+Tab / Alt+Shift+Tab | Window switcher                                                                                                                               |

Plasma's defaults cover the rest: Super+L to lock, Super+E for Dolphin, Print for Spectacle, Super+Arrows to tile, Super+PgUp to maximize, Super+Drag to move, and the volume, media and brightness keys.
