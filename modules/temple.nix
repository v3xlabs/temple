{self, ...}: {
  flake.nixosModules.temple = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.temple;
    theme = cfg.theme;
    hyprland = import ./hyprland.nix {
      inherit lib theme;
      inherit (cfg) monitors input keybinds;
    };
    kittyConfig = import ./kitty.nix {inherit theme;};
    shellSource = self.packages.${pkgs.stdenv.hostPlatform.system}.shell;

    session = pkgs.writeShellScript "temple-session" ''
      export HYPRLAND_CONFIG=/etc/temple/hypr/hyprland.lua
      export KITTY_CONFIG_DIRECTORY=/etc/temple/kitty
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

    # Hyprland runs in a uwsm user unit outside the logind session, so
    # `loginctl lock-session` cannot resolve a session to lock from there.
    lock = pkgs.writeShellApplication {
      name = "temple-lock";
      runtimeInputs = [pkgs.procps config.programs.hyprlock.package];
      text = "pidof hyprlock || hyprlock --config /etc/temple/hypr/hyprlock.conf";
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

    hyprlockConfig = ''
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
        font_size = 72
        position = 0, 90
        halign = center
        valign = center
      }
    '';
  in {
    options.temple = {
      enable = lib.mkEnableOption "the v3x temple desktop session";

      theme = lib.mkOption {
        type = lib.types.attrs;
        default = self.themes.dark;
        description = "Theme attrset, see themes/ for the shape.";
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

      environment.etc = {
        "temple/theme.json".text = builtins.toJSON theme;
        "temple/hypr/hyprland.lua".text = hyprland.lua;
        "temple/keybinds.json".text = builtins.toJSON hyprland.keybinds;
        "temple/hypr/hypridle.conf".text = hypridleConfig;
        "temple/hypr/hyprlock.conf".text = hyprlockConfig;
        "temple/kitty/kitty.conf".text = kittyConfig;
        "temple/shell".source = "${shellSource}/share/temple/shell";
        "temple/backgrounds.json".text = builtins.toJSON (map (background: "${background}") cfg.backgrounds);
      };

      environment.systemPackages = with pkgs; [
        lock
        quickshell
        kitty
        kdePackages.breeze
        kdePackages.dolphin
        kdePackages.kate
        wl-clipboard
      ];

      fonts.packages = with pkgs; [
        inter
        nerd-fonts.hack
      ];

      fonts.fontconfig.defaultFonts = {
        sansSerif = [theme.font.sans];
        monospace = [theme.font.mono];
      };

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
