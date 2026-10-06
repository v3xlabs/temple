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

    stateLink = "$HOME/.local/state/temple/theme";

    session = pkgs.writeShellScript "temple-session" ''
      export HYPRLAND_CONFIG=/etc/temple/hypr/hyprland.lua
      export KITTY_CONFIG_DIRECTORY=/etc/temple/kitty
      # The Hyprland config, kitty and hyprlock read the theme through this link,
      # so it must resolve before Hyprland starts. A removed theme leaves it dangling.
      if [ ! -e "${stateLink}/theme.json" ]; then
        mkdir -p "$HOME/.local/state/temple"
        ln -sfn /etc/temple/themes/${cfg.theme} "${stateLink}"
      fi
      exec ${config.programs.hyprland.package}/bin/start-hyprland
    '';

    sessionPackage = pkgs.runCommand "temple-session-desktop" {passthru.providedSessions = ["temple"];} ''
      mkdir -p $out/share/wayland-sessions
      cat > $out/share/wayland-sessions/temple.desktop <<DESKTOP
      [Desktop Entry]
      Name=Temple
      Comment=v3x temple desktop
      Exec=${lib.getExe config.programs.uwsm.package} start -e -D Hyprland -N Temple -- ${session}
      Type=Application
      DesktopNames=Hyprland
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
        ${hyprctl} eval "$(cat "$dir/hyprland.lua")" >/dev/null
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
        path = ${builtins.head cfg.backgrounds}
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
        variant = lib.mkOption {type = lib.types.enum ["dark" "light"];};
        style = lib.mkOption {
          type = lib.types.enum ["temple" "xp" "win7"];
          description = "Bar the shell draws. Each style reads its own tokens from `bar`.";
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
        };
        window = {
          border = lib.mkOption {type = lib.types.ints.unsigned;};
          active = lib.mkOption {
            type = lib.types.nonEmptyListOf colour;
            description = "Active window border. More than one colour draws a gradient.";
          };
          inactive = lib.mkOption {type = lib.types.nonEmptyListOf colour;};
        };
        bar = lib.mkOption {
          type = lib.types.attrsOf (lib.types.oneOf [lib.types.str lib.types.number]);
          default = {};
          description = "Tokens for the bar style.";
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
        default = "dark";
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
          description = "Outputs that show a bar at the top edge (style `temple`), by connector name as `hyprctl monitors` prints it. An empty list shows it on every output.";
        };
        bottom = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
          example = ["DP-4"];
          description = "Outputs that show a bar at the bottom edge (styles `xp` and `win7`). An empty list shows it on every output.";
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
              exec = [(lib.getExe cfg.terminal)];
            }
            {
              label = "Files";
              exec = ["dolphin"];
            }
            {
              label = "Editor";
              exec = ["kate"];
            }
            {
              label = "Screenshot a region";
              exec = [(lib.getExe screenshot) "region"];
            }
            {
              label = "Lock";
              exec = [(lib.getExe lock)];
            }
          ];
          "temple/hypr/hyprland.lua".text = hyprland.lua;
          "temple/keybinds.json".text = builtins.toJSON hyprland.keybinds;
          "temple/hypr/hypridle.conf".text = hypridleConfig;
          "temple/kitty/kitty.conf".text = kitty.config;
          "temple/shell".source = "${shellSource}/share/temple/shell";
          "temple/backgrounds.json".text = builtins.toJSON (map (background: "${background}") cfg.backgrounds);
          "temple/bar.json".text = builtins.toJSON {inherit (cfg.bar) monitors;};
        }
        // lib.concatMapAttrs themeFiles cfg.themes;

      environment.systemPackages = with pkgs; [
        applyTheme
        lock
        screenshot
        quickshell
        cfg.terminal
        kdePackages.breeze
        kdePackages.dolphin
        kdePackages.kate
        wl-clipboard
      ];

      fonts.packages = with pkgs; [
        inter
        nerd-fonts.hack
        open-sans
        tahoma
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
