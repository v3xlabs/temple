{self, ...}: {
  flake.nixosModules.temple = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.temple;
    hyprctl = "${config.programs.hyprland.package}/bin/hyprctl";
    hyprland = import ./hyprland.nix {
      inherit lib;
      inherit (cfg) monitors input keybinds;
      autostart = lib.optional cfg.kwallet.enable "${config.security.pam.services.login.kwallet.package}/libexec/pam_kwallet_init";
      hyprbars = pkgs.hyprlandPlugins.hyprbars;
      titlebarExclude = cfg.titlebars.exclude;
      defaultTheme = cfg.theme;
      exe = {
        terminal = lib.getExe cfg.terminal;
        screenshot = lib.getExe screenshot;
        wpctl = lib.getExe' pkgs.wireplumber "wpctl";
        playerctl = lib.getExe pkgs.playerctl;
        brightnessctl = lib.getExe pkgs.brightnessctl;
      };
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

    # Electron, Chromium and Qt pick the KDE wallet and platform theme only when
    # the desktop list names KDE. Hyprland stays first, so its portals win.
    desktopNames = "Hyprland" + lib.optionalString cfg.kwallet.enable ":KDE";

    session = pkgs.writeShellScript "temple-session" ''
      export HYPRLAND_CONFIG=/etc/temple/hypr/hyprland.lua
      export KITTY_CONFIG_DIRECTORY=/etc/temple/kitty
      ${lib.optionalString cfg.kwallet.enable "export KDE_SESSION_VERSION=6"}
      # The Hyprland config, kitty and hyprlock read the theme through this link,
      # so it must resolve before Hyprland starts. A removed theme leaves it dangling.
      if [ ! -e "${stateLink}/theme.json" ]; then
        mkdir -p "$HOME/.local/state/temple"
        ln -sfn /etc/temple/themes/${cfg.theme} "${stateLink}"
      fi
      # The chosen wallpaper; hyprlock reads it, the background picker replaces it.
      if [ ! -e "$HOME/.local/state/temple/background" ]; then
        mkdir -p "$HOME/.local/state/temple"
        ln -sfn ${builtins.head cfg.backgrounds} "$HOME/.local/state/temple/background"
      fi
      exec ${config.programs.hyprland.package}/bin/start-hyprland
    '';

    sessionPackage = pkgs.runCommand "temple-session-desktop" {passthru.providedSessions = ["temple"];} ''
      mkdir -p $out/share/wayland-sessions
      cat > $out/share/wayland-sessions/temple.desktop <<DESKTOP
      [Desktop Entry]
      Name=Temple
      Comment=v3x temple desktop
      Exec=${lib.getExe config.programs.uwsm.package} start -e -D ${desktopNames} -N Temple -- ${session}
      Type=Application
      DesktopNames=${lib.replaceStrings [":"] [";"] desktopNames}
      DESKTOP
    '';

    applyTheme = pkgs.writeShellApplication {
      name = "temple-apply-theme";
      runtimeInputs = [pkgs.coreutils pkgs.procps];
      text = ''
        dir=/etc/temple/themes/''${1:?usage: temple-apply-theme <theme>}
        if [ ! -e "$dir/theme.json" ]; then
          echo "temple-apply-theme: no theme $1 in /etc/temple/themes" >&2
          exit 1
        fi
        mkdir -p "$HOME/.local/state/temple"
        ln -sfn "$dir" "${stateLink}"
        ${hyprctl} reload >/dev/null
        # Kitty rereads its config on SIGUSR1. Wrappers rename the binary, so match argv0.
        pkill -USR1 -f '^([^ ]*/)?kitty( |$)' || true
      '';
    };

    # Hyprland runs in a uwsm user unit outside the logind session, so
    # `loginctl lock-session` cannot resolve a session to lock from there.
    lock = pkgs.writeShellApplication {
      name = "temple-lock";
      runtimeInputs = [pkgs.procps config.programs.hyprlock.package];
      text = ''pidof hyprlock || hyprlock --config "${stateLink}/hyprlock.conf"'';
    };

    screenshot = pkgs.writeShellApplication {
      name = "temple-screenshot";
      runtimeInputs = [pkgs.coreutils pkgs.grim pkgs.slurp pkgs.wl-clipboard pkgs.libnotify];
      text = ''
        dir="$HOME/Pictures/Screenshots"
        mkdir -p "$dir"
        file="$dir/$(date +%Y-%m-%d_%H-%M-%S).png"
        case "''${1:-region}" in
          region)
            geometry=$(slurp) || exit 0
            grim -g "$geometry" "$file"
            ;;
          screen) grim "$file" ;;
          *)
            echo "usage: temple-screenshot [region|screen]" >&2
            exit 1
            ;;
        esac
        wl-copy --type image/png < "$file"
        notify-send -a Screenshot -i "$file" "Screenshot copied" "$file"
      '';
    };

    hypridleConfig = ''
      general {
        lock_cmd = "${lib.getExe lock}"
        before_sleep_cmd = "${lib.getExe lock}"
      }

      listener {
        timeout = ${toString cfg.idle.timeout}
        on-timeout = "${lib.getExe lock}"
      }
    '';

    hyprlockConfig = theme: ''
      background {
        monitor =
        path = ~/.local/state/temple/background
        blur_passes = 3
      }

      input-field {
        monitor =
        size = 280, 52
        outline_thickness = 1
        outer_color = rgb(${lib.removePrefix "#" theme.accent})
        inner_color = rgb(${lib.removePrefix "#" theme.palette.base00})
        font_color = rgb(${lib.removePrefix "#" theme.palette.base05})
        font_family = ${theme.font.sans}
        rounding = ${toString theme.radius}
        fade_on_empty = false
        placeholder_text = Password
        position = 0, -20
        halign = center
        valign = center
      }

      label {
        monitor =
        text = cmd[update:1000] echo "$(date '+%H:%M')"
        color = rgb(${lib.removePrefix "#" theme.palette.base05})
        font_family = ${theme.font.sans}
        font_size = 72
        position = 0, 90
        halign = center
        valign = center
      }
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
      "temple/themes/${name}/hyprland.lua".text = hyprland.themeLua theme;
      "temple/themes/${name}/kitty.conf".text = kitty.theme theme;
      "temple/themes/${name}/hyprlock.conf".text = hyprlockConfig theme;
    };
  in {
    options.temple = {
      enable = lib.mkEnableOption "the v3x temple desktop session";

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
        description = "Images displayed behind Temple windows. Screen N shows entry N modulo the list length. Hyprlock shows the first entry.";
      };

      input.layout = lib.mkOption {
        type = lib.types.str;
        default = "us";
        description = "XKB layout passed to Hyprland.";
      };

      keybinds = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule {
          options = {
            key = lib.mkOption {
              type = lib.types.str;
              example = "Alt+Shift+R";
              description = "Modifiers and one key joined by `+`, in the notation Plasma uses. Modifiers are Meta, Ctrl, Alt and Shift. The key is an XKB key name. Spaces in it become `_`, so Plasma's `Scroll Lock` binds `Scroll_Lock`.";
            };
            command = lib.mkOption {
              type = lib.types.str;
              example = "kitty";
              description = "Shell command that runs when the key is pressed.";
            };
            description = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Label that `hyprctl binds` shows for this bind.";
            };
          };
        });
        default = {};
        example = lib.literalExpression ''{ terminal = { key = "Alt+K"; command = "kitty"; }; }'';
        description = "User keybinds, added after the Temple defaults.";
      };

      monitors = lib.mkOption {
        type = lib.types.listOf (lib.types.submodule {
          options = {
            output = lib.mkOption {type = lib.types.str;};
            mode = lib.mkOption {type = lib.types.str;};
            position = lib.mkOption {type = lib.types.str;};
            scale = lib.mkOption {type = lib.types.oneOf [lib.types.int lib.types.str];};
          };
        });
        default = [
          {
            output = "";
            mode = "preferred";
            position = "auto";
            scale = 1;
          }
        ];
        description = "Hyprland monitor rules in declaration order.";
      };

      bar.monitors = {
        top = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
          example = ["DP-5"];
          description = "Outputs that show a bar at the top edge, by connector name as `hyprctl monitors` prints it. An empty list shows it on every output. The XP and Windows 7 themes draw no top bar.";
        };
        bottom = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
          example = ["DP-4"];
          description = "Outputs that show a bar at the bottom edge, such as the XP and Windows 7 taskbars. An empty list shows it on every output.";
        };
      };

      titlebars.exclude = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "chromium(-browser)?"
          "[Gg]oogle-chrome"
          "brave-browser"
          "firefox"
          "code"
          "code-url-handler"
          "codium"
          "VSCodium"
          "discord"
          "vesktop"
          "obsidian"
          "Mattermost"
          "[Ss]potify"
          "Slack"
          "steam"
          "org\\.gnome\\..*"
        ];
        description = "Window classes, as regular expressions, that draw their own title bar and get no Temple title bar.";
      };

      kwallet.enable = lib.mkOption {
        type = lib.types.bool;
        default = config.services.desktopManager.plasma6.enable;
        defaultText = lib.literalExpression "config.services.desktopManager.plasma6.enable";
        description = "Use KWallet 6 for secrets, so apps like Signal share their keys with a Plasma session. The login password unlocks the wallet.";
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

      idle.timeout = lib.mkOption {
        type = lib.types.ints.positive;
        default = 300;
        description = "Seconds without activity before Temple locks the session.";
      };
    };

    config = lib.mkIf cfg.enable {
      programs.hyprland = {
        enable = true;
        withUWSM = true;
      };
      programs.hyprlock.enable = true;
      services.hypridle.enable = true;

      services.displayManager.sessionPackages = [sessionPackage];

      temple.themes = lib.mapAttrs (_: lib.mkDefault) self.themes;

      security.pam.services.login.kwallet.enable = lib.mkIf cfg.kwallet.enable true;

      assertions = [
        {
          assertion = cfg.themes ? ${cfg.theme};
          message = "temple.theme is \"${cfg.theme}\", expected one of ${lib.concatStringsSep ", " (lib.attrNames cfg.themes)}";
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
              exec = [(lib.getExe screenshot) "region"];
            }
            {
              label = "Lock";
              icon = "preferences-desktop-user-password";
              exec = [(lib.getExe lock)];
            }
          ];
          "temple/hypr/hyprland.lua".text = hyprland.lua;
          "temple/keybinds.json".text = builtins.toJSON hyprland.keybinds;
          "temple/hypr/hypridle.conf".text = hypridleConfig;
          "temple/kitty/kitty.conf".text = kitty.config;
          "temple/shell".source = "${shellSource}/share/temple/shell";
          "temple/backgrounds.json".text = builtins.toJSON (map (background: "${background}") cfg.backgrounds);
          "temple/shell.json".text = builtins.toJSON {inherit (cfg) bar activateLinux;};
        }
        // lib.concatMapAttrs themeFiles cfg.themes;

      environment.systemPackages = with pkgs;
        [
          applyTheme
          lock
          screenshot
          shell
          cfg.terminal
          kdePackages.breeze
          kdePackages.breeze-icons
          kdePackages.dolphin
          kdePackages.kate
          wl-clipboard
          pavucontrol
          networkmanagerapplet
        ]
        ++ lib.optional cfg.kwallet.enable kdePackages.kwallet;

      fonts.packages = with pkgs; [
        inter
        nerd-fonts.hack
        open-sans
        tahoma
        sanFrancisco
        templeosFont
      ];

      systemd.user.services = {
        hypridle.serviceConfig.ExecStart = lib.mkForce [
          ""
          "${config.services.hypridle.package}/bin/hypridle --config /etc/temple/hypr/hypridle.conf"
        ];

        temple-polkit-agent = {
          wantedBy = ["graphical-session.target"];
          partOf = ["graphical-session.target"];
          serviceConfig = {
            ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
            Restart = "on-failure";
            RestartSec = 2;
          };
        };
      };

      environment.sessionVariables.NIXOS_OZONE_WL = "1";
    };
  };

  flake.nixosModules.default = self.nixosModules.temple;
}
