{self, ...}: {
  flake.nixosModules.temple = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.temple;
    luna = pkgs.callPackage ./luna.nix {};
    kwinThemes = pkgs.callPackage ./kwin.nix {
      inherit (cfg) themes;
      inherit luna;
    };
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
    wallpapers = pkgs.callPackage ./wallpapers.nix {};
    clippy = pkgs.callPackage ./clippy.nix {};

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

    # Plain Plasma never reads these. The Temple session puts the active
    # theme's xdg directory and /etc/temple/xdg in front of XDG_CONFIG_DIRS,
    # and /etc/temple/share in front of XDG_DATA_DIRS. `[$i]` locks a key, so
    # the value a user set for plain Plasma in ~/.config cannot override it.
    # Locking whole groups instead would make KConfig write the lock into
    # ~/.config the next time KWin saves kwinrc. The switcher shows live
    # previews, so KWin need not fade every other window, the Temple bar and
    # background included, while it is open.
    kwinrc = name: ''
      [org.kde.kdecoration2]
      library[$i]=org.kde.kwin.aurorae
      theme[$i]=temple-${name}

      [TabBox]
      LayoutName[$i]=temple-${name}
      HighlightWindows[$i]=false
    '';

    # KPackage refuses package files that are symlinks out of the package
    # directory, so the files are copied rather than linked.
    sessionData = pkgs.runCommand "temple-session-data" {} ''
      mkdir -p $out/share
      cp -rL ${kwinThemes}/share/. ${shortcuts}/share/. $out/share/
    '';

    # Kitty, the shell and the lock screen read the theme and wallpaper through
    # these links, and the session's config path runs through the theme link,
    # so both must resolve before Plasma starts. A removed theme leaves the link
    # dangling.
    session = pkgs.writeShellScript "temple-session" ''
      mkdir -p "$HOME/.local/state/temple"
      if [ ! -e "${stateLink}/theme.json" ]; then
        ln -sfn /etc/temple/themes/${cfg.theme} "${stateLink}"
      fi
      if [ ! -e "$HOME/.local/state/temple/background" ]; then
        ln -sfn ${builtins.head cfg.backgrounds} "$HOME/.local/state/temple/background"
      fi
      export XDG_SESSION_DESKTOP=temple
      export XDG_CONFIG_DIRS="${stateLink}/xdg:/etc/temple/xdg:''${XDG_CONFIG_DIRS:-/etc/xdg}"
      export XDG_DATA_DIRS="/etc/temple/share:''${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
      export KITTY_CONFIG_DIRECTORY=/etc/temple/kitty
      exec ${pkgs.kdePackages.plasma-workspace}/libexec/plasma-dbus-run-session-if-needed ${pkgs.kdePackages.plasma-workspace}/bin/startplasma-wayland
    '';

    sessionPackage = pkgs.writeTextFile {
      name = "temple-session-desktop";
      destination = "/share/wayland-sessions/temple.desktop";
      text = ''
        [Desktop Entry]
        Type=Application
        Name=Temple
        Comment=Plasma with the v3x temple shell
        Exec=${session}
        DesktopNames=KDE
      '';
      passthru.providedSessions = ["temple"];
    };

    # startplasma hands the session's environment to the user's systemd units.
    inTemple = "${pkgs.bash}/bin/sh -c 'test \"$$XDG_SESSION_DESKTOP\" = temple'";
    notInTemple = "${pkgs.bash}/bin/sh -c 'test \"$$XDG_SESSION_DESKTOP\" != temple'";

    applyTheme = pkgs.writeShellApplication {
      name = "temple-apply-theme";
      runtimeInputs = [pkgs.coreutils pkgs.procps pkgs.systemd];
      text = ''
        dir=/etc/temple/themes/''${1:?usage: temple-apply-theme <theme>}
        if [ ! -e "$dir/theme.json" ]; then
          echo "temple-apply-theme: no theme $1 in /etc/temple/themes" >&2
          exit 1
        fi
        mkdir -p "$HOME/.local/state/temple"
        ln -sfn "$dir" "${stateLink}"
        # KWin rereads kwinrc, now through the moved link.
        busctl --user call org.kde.KWin /KWin org.kde.KWin reconfigure
        # Kitty rereads its config on SIGUSR1. Wrappers rename the binary, so match argv0.
        pkill -USR1 -f '^([^ ]*/)?kitty( |$)' || true
      '';
    };

    ipc = function: "${shell}/bin/qs -p /etc/temple/shell ipc call shell ${function}";
    kwinShortcut = name: "${pkgs.systemd}/bin/busctl --user call org.kde.kglobalaccel /component/kwin org.kde.kglobalaccel.Component invokeShortcut s ${lib.escapeShellArg name}";

    # A bind runs either a `command`, or an `action`: a function of the shell's
    # `shell` IPC target.
    defaultBinds = {
      start = {
        keys = ["Meta"];
        action = "toggleStart";
        description = "Start menu";
      };
      palette = {
        keys = ["Meta+K"];
        action = "togglePalette";
        description = "Command palette";
      };
      keybinds = {
        keys = ["Meta+/"];
        action = "toggleKeybinds";
        description = "Show keybinds";
      };
      themes = {
        keys = ["Meta+T"];
        action = "toggleThemes";
        description = "Pick theme";
      };
      backgrounds = {
        keys = ["Meta+B"];
        action = "toggleBackgrounds";
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
    actionBinds = lib.filterAttrs (_: bind: bind ? action) binds;
    commandBinds = lib.filterAttrs (_: bind: bind ? command) binds;

    # A kglobalaccel component: KWin's shortcut daemon finds it in
    # share/kglobalaccel and runs an action's Exec when one of its keys is pressed.
    shortcuts = pkgs.writeTextDir "share/kglobalaccel/temple.desktop" ''
      [Desktop Entry]
      Type=Application
      Name=Temple
      Exec=${ipc "toggleStart"}
      X-KDE-GlobalShortcutType=Service
      Actions=${lib.concatStringsSep ";" (lib.attrNames commandBinds)}
      ${lib.concatStrings (lib.mapAttrsToList (id: bind: ''

          [Desktop Action ${id}]
          Name=${bind.description}
          Exec=${pkgs.writeShellScript "temple-${id}" bind.command}
          X-KDE-Shortcuts=${lib.concatStringsSep "," bind.keys}
        '')
        commandBinds)}
    '';

    # kglobalaccel's D-Bus API takes a key as a Qt key code.
    qtModifiers = {
      Shift = 33554432;
      Ctrl = 67108864;
      Alt = 134217728;
      Meta = 268435456;
    };
    qtNamedKeys =
      {
        Meta = 16777250;
        Escape = 16777216;
        Tab = 16777217;
        Return = 16777220;
        Space = 32;
      }
      // lib.listToAttrs (lib.genList (n: lib.nameValuePair "F${toString (n + 1)}" (16777264 + n)) 12);
    qtKey = key: let
      parts = lib.splitString "+" key;
      name = lib.last parts;
      code =
        qtNamedKeys.${
          name
        }
        or (
          if lib.stringLength name == 1
          then lib.strings.charToInt (lib.toUpper name)
          else throw "temple: no Qt key code for \"${name}\" in ${key}"
        );
    in
      lib.foldl' (sum: modifier: sum + qtModifiers.${modifier}) code (lib.init parts);

    # The shell's actions are kglobalaccel shortcuts of their own. A key press
    # reaches the shell as a D-Bus signal, with no process to start, so text
    # typed right after Super lands in the start menu. The `_k_session:` prefix
    # keeps them out of kglobalshortcutsrc, where plain Plasma would see them.
    # setShortcut's flags 6 are SetPresent and NoAutoloading.
    registerActions = pkgs.writeShellScript "temple-register-actions" (lib.concatStrings (lib.mapAttrsToList (_: bind: let
        id = "4 temple-shell ${lib.escapeShellArg "_k_session:${bind.action}"} 'Temple shell' ${lib.escapeShellArg bind.description}";
        accel = "${pkgs.systemd}/bin/busctl --user call org.kde.kglobalaccel /kglobalaccel org.kde.KGlobalAccel";
      in ''
        ${accel} doRegister as ${id}
        ${accel} setShortcut asaiu ${id} ${toString (lib.length bind.keys)} ${lib.concatMapStringsSep " " (key: toString (qtKey key)) bind.keys} 6 >/dev/null
      '')
      actionBinds));

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
      "temple/themes/${name}/xdg/kwinrc".text = kwinrc name;
    };
  in {
    options.temple = {
      enable = lib.mkEnableOption "the v3x temple desktop: a Temple session next to Plasma 6, with the Temple shell in place of plasmashell";

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
      services.displayManager.sessionPackages = [sessionPackage];
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
          "temple/wallpapers".source = wallpapers;
          "temple/clippy".source = clippy;
          "temple/luna".source = luna;
          "temple/shell.json".text = builtins.toJSON {inherit (cfg) bar activateLinux;};
          "temple/share".source = "${sessionData}/share";
          # Locked, so the lock screen shows the Temple background even where
          # plain Plasma was given another wallpaper.
          "temple/xdg/kscreenlockerrc".text = ''
            [Greeter][Wallpaper][org.kde.image][General]
            Image[$ie]=file://$HOME/.local/state/temple/background
          '';
        }
        // lib.concatMapAttrs themeFiles cfg.themes;

      environment.systemPackages = with pkgs; [
        applyTheme
        shell
        shellGrant
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

      # Both sessions start the same Plasma units. Only the Temple session
      # swaps plasmashell for the Temple shell; the splash screen waits for
      # plasmashell to draw the desktop, so it is skipped there too.
      systemd.user.services = {
        plasma-plasmashell = {
          overrideStrategy = "asDropin";
          enableDefaultPath = false;
          serviceConfig.ExecCondition = notInTemple;
        };
        plasma-ksplash = {
          overrideStrategy = "asDropin";
          enableDefaultPath = false;
          serviceConfig.ExecCondition = notInTemple;
        };
        temple-shell = {
          description = "Temple shell";
          wantedBy = ["plasma-core.target"];
          partOf = ["graphical-session.target"];
          after = ["plasma-ksmserver.service" "plasma-kcminit.service"];
          # Apps started from the shell inherit the session's PATH.
          enableDefaultPath = false;
          serviceConfig = {
            ExecCondition = inTemple;
            ExecStart = "${shell}/bin/qs -p /etc/temple/shell";
            # `-`: a failed registration must not stop the shell.
            ExecStartPost = "-${registerActions}";
            Restart = "on-failure";
            Slice = "session.slice";
          };
        };
      };

      environment.sessionVariables.NIXOS_OZONE_WL = "1";
    };
  };

  flake.nixosModules.default = self.nixosModules.temple;
}
