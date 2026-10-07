{self, ...}: {
  flake.nixosModules.temple = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.temple;
    kwinThemes = pkgs.callPackage ./kwin.nix {inherit (cfg) themes;};
    kitty = import ./kitty.nix;
    shellSource = self.packages.${pkgs.stdenv.hostPlatform.system}.shell;

    # Wine ships Tahoma under the LGPL. Only Tahoma is taken so Wine's Courier
    # and Symbol do not shadow the fonts other apps resolve those names to.
    tahoma = pkgs.runCommand "tahoma" {} ''
      install -Dm444 -t $out/share/fonts/truetype ${pkgs.wineWow64Packages.fonts}/share/fonts/truetype/tahoma{,bd}.ttf
    '';

    # Apple's San Francisco downloads: each dmg holds a pkg whose gzip payload
    # is a cpio archive. 7z unwraps the dmg and pkg layers; cpio the payload.
    # Only the static Text, Display and Mono cuts are kept: the variable SF-Pro.ttf would compete
    # with them in fontconfig's matching.
    sanFrancisco = let
      dmg = name: hash:
        pkgs.fetchurl {
          url = "https://devimages-cdn.apple.com/design/resources/download/${name}.dmg";
          inherit hash;
        };
      pro = dmg "SF-Pro" "sha256-loqzuLH5LC2K9h6waA9cIiTE541ZuYa/AEUCp/wBKRg=";
      mono = dmg "SF-Mono" "sha256-bUoLeOOqzQb5E/ZCzq0cfbSvNO1IhW1xcaLgtV2aeUU=";
    in
      pkgs.runCommand "san-francisco" {nativeBuildInputs = [pkgs.p7zip pkgs.cpio];} ''
        7z x -y -opro ${pro} >/dev/null
        7z x -y -omono ${mono} >/dev/null
        7z x -y -omono 'mono/SFMonoFonts/SF Mono Fonts.pkg' >/dev/null
        for dir in pro mono; do
          (cd $dir && cpio -idm --quiet < 'Payload~')
        done
        install -Dm444 -t $out/share/fonts/opentype pro/Library/Fonts/SF-Pro-{Text,Display}-*.otf mono/Library/Fonts/SF-Mono-*.otf
      '';

    templeosFont = pkgs.callPackage ./templeos-font.nix {};

    stateLink = "$HOME/.local/state/temple/theme";

    # The icon theme is fixed on the binary itself: a shell restarted from a
    # terminal lacks the session's environment and would draw missing icons.
    shell = pkgs.symlinkJoin {
      name = "temple-quickshell";
      paths = [pkgs.quickshell];
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        for program in qs quickshell; do
          wrapProgram $out/bin/$program \
            --set-default QS_ICON_THEME breeze \
            --prefix XDG_DATA_DIRS : ${pkgs.kdePackages.breeze-icons}/share
        done
      '';
    };

    # KWin reads its decoration and Alt+Tab layout from kwinrc. Expects $name.
    # The switcher shows live previews, so KWin need not fade every other
    # window, the Temple bar and background included, while it is open.
    writeKwinTheme = ''
      kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key library org.kde.kwin.aurorae
      kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme "temple-$name"
      kwriteconfig6 --file kwinrc --group TabBox --key LayoutName "temple-$name"
      kwriteconfig6 --file kwinrc --group TabBox --key HighlightWindows false
    '';

    # Runs before KWin starts, so its first frame already wears the theme.
    # Kitty, the shell and the lock screen read the theme and wallpaper through
    # these links. A removed theme leaves the link dangling.
    init = pkgs.writeShellApplication {
      name = "temple-init";
      runtimeInputs = [pkgs.coreutils pkgs.kdePackages.kconfig];
      text = ''
        mkdir -p "$HOME/.local/state/temple"
        if [ ! -e "${stateLink}/theme.json" ]; then
          ln -sfn /etc/temple/themes/${cfg.theme} "${stateLink}"
        fi
        if [ ! -e "$HOME/.local/state/temple/background" ]; then
          ln -sfn ${builtins.head cfg.backgrounds} "$HOME/.local/state/temple/background"
        fi
        name=$(basename "$(readlink "${stateLink}")")
        ${writeKwinTheme}
      '';
    };

    applyTheme = pkgs.writeShellApplication {
      name = "temple-apply-theme";
      runtimeInputs = [pkgs.coreutils pkgs.procps pkgs.systemd pkgs.kdePackages.kconfig];
      text = ''
        name=''${1:?usage: temple-apply-theme <theme>}
        dir=/etc/temple/themes/$name
        if [ ! -e "$dir/theme.json" ]; then
          echo "temple-apply-theme: no theme $name in /etc/temple/themes" >&2
          exit 1
        fi
        mkdir -p "$HOME/.local/state/temple"
        ln -sfn "$dir" "${stateLink}"
        ${writeKwinTheme}
        busctl --user call org.kde.KWin /KWin org.kde.KWin reconfigure
        # Kitty rereads its config on SIGUSR1. Wrappers rename the binary, so match argv0.
        pkill -USR1 -f '^([^ ]*/)?kitty( |$)' || true
      '';
    };

    ipc = function: "${shell}/bin/qs -p /etc/temple/shell ipc call shell ${function}";
    kwinShortcut = name: "${pkgs.systemd}/bin/busctl --user call org.kde.kglobalaccel /component/kwin org.kde.kglobalaccel.Component invokeShortcut s ${lib.escapeShellArg name}";

    defaultBinds = {
      start = {
        keys = ["Meta"];
        command = ipc "toggleStart";
        description = "Start menu";
      };
      palette = {
        keys = ["Meta+K"];
        command = ipc "togglePalette";
        description = "Command palette";
      };
      keybinds = {
        keys = ["Meta+/"];
        command = ipc "toggleKeybinds";
        description = "Show keybinds";
      };
      themes = {
        keys = ["Meta+T"];
        command = ipc "toggleThemes";
        description = "Pick theme";
      };
      backgrounds = {
        keys = ["Meta+B"];
        command = ipc "toggleBackgrounds";
        description = "Pick background";
      };
      terminal = {
        keys = ["Meta+Return" "Alt+K"];
        command = lib.getExe cfg.terminal;
        description = "Terminal";
      };
      close = {
        keys = ["Meta+Q"];
        command = kwinShortcut "Window Close";
        description = "Close window";
      };
      fullscreen = {
        keys = ["Meta+F"];
        command = kwinShortcut "Window Fullscreen";
        description = "Fullscreen";
      };
    };

    # A user bind takes its key away from the default that had it.
    userKeys = map (bind: lib.toLower bind.key) (lib.attrValues cfg.keybinds);
    duplicateKeys = lib.filter (key: lib.count (k: k == key) userKeys > 1) (lib.unique userKeys);
    binds =
      lib.filterAttrs (_: bind: bind.keys != []) (lib.mapAttrs (_: bind: bind // {keys = lib.filter (key: !(lib.elem (lib.toLower key) userKeys)) bind.keys;}) defaultBinds)
      // lib.mapAttrs' (id: bind:
        lib.nameValuePair "user-${id}" {
          keys = [bind.key];
          inherit (bind) command;
          description = lib.defaultTo bind.command bind.description;
        })
      cfg.keybinds;

    # A kglobalaccel component: KWin's shortcut daemon finds it in
    # share/kglobalaccel and runs an action's Exec when one of its keys is pressed.
    shortcuts = pkgs.writeTextDir "share/kglobalaccel/temple.desktop" ''
      [Desktop Entry]
      Type=Application
      Name=Temple
      Exec=${ipc "toggleStart"}
      X-KDE-GlobalShortcutType=Service
      Actions=${lib.concatStringsSep ";" (lib.attrNames binds)}
      ${lib.concatStrings (lib.mapAttrsToList (id: bind: ''

          [Desktop Action ${id}]
          Name=${bind.description}
          Exec=${pkgs.writeShellScript "temple-${id}" bind.command}
          X-KDE-Shortcuts=${lib.concatStringsSep "," bind.keys}
        '')
        binds)}
    '';

    # KWin shares the window list and window previews only with binaries a
    # desktop file names. The nixpkgs KWin resolves the `.quickshell-wrapped`
    # binary back to the `quickshell` wrapper, so Exec names the wrapper.
    shellGrant = pkgs.writeTextDir "share/applications/temple-shell.desktop" ''
      [Desktop Entry]
      Type=Application
      Name=Temple shell
      NoDisplay=true
      Exec=${pkgs.quickshell}/bin/quickshell
      X-KDE-Wayland-Interfaces=org_kde_plasma_window_management,zkde_screencast_unstable_v1
    '';

    colour = lib.types.strMatching "#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})";
    base16 = lib.types.attrsOf colour;
    themeType = lib.types.submodule ({config, ...}: {
      options = {
        label = lib.mkOption {
          type = lib.types.str;
          description = "Name the theme picker shows.";
        };
        style = lib.mkOption {
          type = lib.types.enum ["xp" "win7" "macos" "templeos"];
          description = "Desktop the bar, start menu and session dialogs imitate. Skins of one style read the same tokens from `bar`.";
        };
        skin = lib.mkOption {
          type = lib.types.enum ["drawn" "msstyles" "sequoia" "tahoe"];
          default = "drawn";
          description = "How the bar is painted: `drawn` from gradients and the `bar` tokens, `msstyles` from bitmaps of the original Windows visual style. The `macos` style names the macOS release it follows: `sequoia` (macOS 15, translucent menu bar) or `tahoe` (macOS 26, Liquid Glass); both draw from the `bar` tokens.";
        };
        edge = lib.mkOption {
          type = lib.types.enum ["top" "bottom"];
          description = "Screen edge the bar sits on. Flyouts and notifications open away from it, and `temple.bar.monitors` has one list per edge.";
        };
        frame = lib.mkOption {
          type = lib.types.enum ["plain" "glass" "text"];
          default = "plain";
          description = "How tray flyouts and the notification centre are framed: `plain` from their `color`, `border` and `radius` tokens, `glass` as the macOS material from the `bar` tokens, `text` as a TempleOS text-mode border.";
        };
        lineWidth = lib.mkOption {
          type = lib.types.ints.positive;
          default = 1;
          description = "Thickness of separator lines in flyouts and the notification centre.";
        };
        palette = lib.mkOption {
          type = base16;
          description = "base16 palette for shell surfaces.";
        };
        terminal = lib.mkOption {
          type = base16;
          default = config.palette;
          defaultText = lib.literalExpression "palette";
          description = "base16 palette for kitty.";
        };
        accent = lib.mkOption {type = colour;};
        glass = {
          tint = lib.mkOption {type = colour;};
          opacity = lib.mkOption {type = lib.types.numbers.between 0 1;};
          blur = lib.mkOption {type = lib.types.ints.unsigned;};
          border = lib.mkOption {type = colour;};
        };
        radius = lib.mkOption {type = lib.types.ints.unsigned;};
        font = {
          sans = lib.mkOption {type = lib.types.str;};
          mono = lib.mkOption {type = lib.types.str;};
          size = lib.mkOption {type = lib.types.ints.positive;};
          bitmap = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "The sans font is a bitmap font: flyouts and notifications draw text only at `size` and never bold.";
          };
        };
        window = {
          border = lib.mkOption {type = lib.types.ints.unsigned;};
          active = lib.mkOption {
            type = lib.types.nonEmptyListOf colour;
            description = "Active window border. More than one colour draws a gradient.";
          };
          inactive = lib.mkOption {type = lib.types.nonEmptyListOf colour;};
          rounding = lib.mkOption {
            type = lib.types.ints.unsigned;
            default = 0;
            description = "Corner radius of windows in pixels.";
          };
          titlebar = let
            token = default:
              lib.mkOption {
                type = colour;
                inherit default;
              };
          in {
            color = token config.palette.base01;
            text = token config.palette.base05;
            button = token config.palette.base02;
            buttonText = token config.palette.base05;
            close = token config.palette.base08;
            closeText = token config.palette.base00;
            minimize = token config.window.titlebar.button;
            maximize = token config.window.titlebar.button;
            align = lib.mkOption {
              type = lib.types.enum ["left" "right"];
              default = "right";
              description = "Edge of the title bar that holds the buttons. `left` orders them close, minimize, maximize from the edge, like macOS.";
            };
          };
        };
        bar = lib.mkOption {
          type = lib.types.attrsOf (lib.types.oneOf [lib.types.str lib.types.number]);
          default = {};
          description = "Tokens for the bar style.";
        };
        tray = lib.mkOption {
          type = lib.types.attrsOf lib.types.anything;
          description = "Tokens for the tray icons, flyouts, tooltips and the volume and network flyouts. See themes/xp.nix for the full set.";
        };
        notifications = lib.mkOption {
          type = lib.types.attrsOf lib.types.anything;
          description = "Tokens for notification popups, the notification centre, action buttons and close buttons. See themes/xp.nix for the full set.";
        };
      };
    });

    themeFiles = name: theme: {
      "temple/themes/${name}/theme.json".text = builtins.toJSON (theme // {inherit name;});
      "temple/themes/${name}/kitty.conf".text = kitty.theme theme;
    };
  in {
    options.temple = {
      enable = lib.mkEnableOption "the v3x temple desktop: Plasma 6 with the Temple shell in place of plasmashell";

      themes = lib.mkOption {
        type = lib.types.attrsOf themeType;
        description = "Themes the picker offers. The built-in themes are always present unless an entry with the same name replaces one. See themes/ for examples.";
      };

      theme = lib.mkOption {
        type = lib.types.str;
        default = "win7-black";
        description = "Theme a user starts with until they pick another one. The pick is kept in ~/.local/state/temple/theme.";
      };

      terminal = lib.mkOption {
        type = lib.types.package;
        default = pkgs.kitty;
        defaultText = lib.literalExpression "pkgs.kitty";
        description = "Terminal that Super+Return, Alt+K and the launcher open. Its main program must be set.";
      };
      backgrounds = lib.mkOption {
        type = lib.types.nonEmptyListOf lib.types.path;
        default = [../shell/bg.png];
        description = "Images displayed behind Temple windows. Screen N shows entry N modulo the list length. The lock screen shows the first entry until a background is picked.";
      };

      keybinds = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule {
          options = {
            key = lib.mkOption {
              type = lib.types.str;
              example = "Alt+Shift+R";
              description = "Modifiers and one key joined by `+`, in the notation Plasma uses, such as `Meta+Shift+Return` or `Scroll Lock`. A modifier alone, such as `Meta`, fires when it is tapped.";
            };
            command = lib.mkOption {
              type = lib.types.str;
              example = "kitty";
              description = "Shell command that runs when the key is pressed.";
            };
            description = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Label that the keybind overview and System Settings show for this bind.";
            };
          };
        });
        default = {};
        example = lib.literalExpression ''{ notes = { key = "Meta+N"; command = "kate"; }; }'';
        description = "User keybinds, added to the Temple defaults. Names may use letters, digits and `-`. A bind with the key of a default replaces that default. KWin's own shortcuts stay in System Settings.";
      };

      bar.monitors = {
        top = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
          example = ["DP-5"];
          description = "Outputs that show a bar at the top edge, by connector name as System Settings' Display page names it. An empty list shows it on every output. The XP and Windows 7 themes draw no top bar.";
        };
        bottom = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
          example = ["DP-4"];
          description = "Outputs that show a bar at the bottom edge, such as the XP and Windows 7 taskbars. An empty list shows it on every output.";
        };
      };

      activateLinux = {
        enable = lib.mkEnableOption "the \"Activate Linux\" watermark. A bar icon turns it on and off";
        monitors = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
          example = ["DP-4"];
          description = "Outputs that show the watermark, by connector name. An empty list shows it on every output.";
        };
      };
    };

    config = lib.mkIf cfg.enable {
      services.desktopManager.plasma6.enable = true;
      hardware.graphics.enable = lib.mkDefault true;

      temple.themes = lib.mapAttrs (_: lib.mkDefault) self.themes;

      assertions = [
        {
          assertion = cfg.themes ? ${cfg.theme};
          message = "temple.theme is \"${cfg.theme}\", expected one of ${lib.concatStringsSep ", " (lib.attrNames cfg.themes)}";
        }
        {
          assertion = duplicateKeys == [];
          message = "temple.keybinds: more than one bind uses ${lib.concatStringsSep ", " duplicateKeys}";
        }
        {
          assertion = lib.all (id: builtins.match "[A-Za-z0-9-]+" id != null) (lib.attrNames cfg.keybinds);
          message = "temple.keybinds: names may only use letters, digits and -";
        }
      ];

      environment.etc =
        {
          "temple/themes.json".text = builtins.toJSON {
            default = cfg.theme;
            themes = lib.mapAttrs (name: theme: theme // {inherit name;}) cfg.themes;
          };
          "temple/commands.json".text = builtins.toJSON [
            {
              label = "Terminal";
              icon = "utilities-terminal";
              exec = [(lib.getExe cfg.terminal)];
            }
            {
              label = "Files";
              icon = "system-file-manager";
              exec = ["dolphin"];
            }
            {
              label = "Editor";
              icon = "accessories-text-editor";
              exec = ["kate"];
            }
            {
              label = "Screenshot a region";
              icon = "applets-screenshooter";
              exec = ["spectacle" "--region"];
            }
            {
              label = "Lock";
              icon = "preferences-desktop-user-password";
              exec = ["busctl" "--user" "call" "org.freedesktop.ScreenSaver" "/ScreenSaver" "org.freedesktop.ScreenSaver" "Lock"];
            }
          ];
          "temple/keybinds.json".text = builtins.toJSON (lib.concatLists (lib.mapAttrsToList (_: bind:
            map (key: {
              inherit key;
              inherit (bind) description;
            })
            bind.keys)
          binds));
          "temple/kitty/kitty.conf".text = kitty.config;
          "temple/shell".source = "${shellSource}/share/temple/shell";
          "temple/backgrounds.json".text = builtins.toJSON (map (background: "${background}") cfg.backgrounds);
          "temple/shell.json".text = builtins.toJSON {inherit (cfg) bar activateLinux;};
          "xdg/kscreenlockerrc".text = ''
            [Greeter][Wallpaper][org.kde.image][General]
            Image[$e]=file://$HOME/.local/state/temple/background
          '';
        }
        // lib.concatMapAttrs themeFiles cfg.themes;

      environment.systemPackages = with pkgs; [
        applyTheme
        shell
        shellGrant
        shortcuts
        kwinThemes
        cfg.terminal
        kdePackages.aurorae
        kdePackages.dolphin
        kdePackages.kate
        kdePackages.spectacle
        pavucontrol
        networkmanagerapplet
      ];

      fonts.packages = with pkgs; [
        inter
        nerd-fonts.hack
        open-sans
        tahoma
        sanFrancisco
        templeosFont
      ];

      systemd.user.services = {
        # The Temple shell takes plasmashell's place in the Plasma session. The
        # splash screen waits for plasmashell to draw the desktop, so it goes too.
        plasma-plasmashell.enable = false;
        plasma-ksplash.enable = false;
        temple-shell = {
          description = "Temple shell";
          wantedBy = ["plasma-core.target"];
          partOf = ["graphical-session.target"];
          after = ["plasma-ksmserver.service" "plasma-kcminit.service"];
          # Apps started from the shell inherit the session's PATH.
          enableDefaultPath = false;
          serviceConfig = {
            ExecStart = "${shell}/bin/qs -p /etc/temple/shell";
            Restart = "on-failure";
            Slice = "session.slice";
          };
        };
        plasma-kwin_wayland = {
          overrideStrategy = "asDropin";
          enableDefaultPath = false;
          serviceConfig.ExecStartPre = lib.getExe init;
        };
      };

      environment.sessionVariables = {
        KITTY_CONFIG_DIRECTORY = "/etc/temple/kitty";
        NIXOS_OZONE_WL = "1";
      };
    };
  };

  flake.nixosModules.default = self.nixosModules.temple;
}
