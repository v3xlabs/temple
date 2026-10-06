{
  lib,
  monitors,
  input,
  keybinds,
  exe,
}: let
  monitorRule = m: "hl.monitor({ output = ${builtins.toJSON m.output}, mode = ${builtins.toJSON m.mode}, position = ${builtins.toJSON m.position}, scale = ${builtins.toJSON (toString m.scale)} })";

  modifiers = {
    Meta = "SUPER";
    Ctrl = "CTRL";
    Alt = "ALT";
    Shift = "SHIFT";
  };
  bindKey = mods: key: lib.concatStringsSep " + " (lib.filter (m: lib.elem m mods) ["SUPER" "CTRL" "ALT" "SHIFT"] ++ [key]);
  hyprlandKey = id: key: let
    parts = lib.splitString "+" key;
    mods = lib.init parts;
    unknown = lib.filter (m: !(modifiers ? ${m})) mods;
  in
    if key == "" || lib.last parts == "" || unknown != []
    then throw "temple.keybinds.${id}.key: cannot parse \"${key}\", expected modifiers from ${lib.concatStringsSep ", " (lib.attrNames modifiers)} and one key, joined by +"
    else bindKey (map (m: modifiers.${m}) mods) (lib.replaceStrings [" "] ["_"] (lib.last parts));

  exec = command: "hl.dsp.exec_cmd(${builtins.toJSON command})";
  cycle = next: "function() hl.dispatch(hl.dsp.window.cycle_next({ next = ${lib.boolToString next} })) hl.dispatch(hl.dsp.window.bring_to_top()) end";
  bind = action: description: {
    inherit action description;
    flags = {};
  };
  # Media keys keep working on the lock screen and repeat while held.
  mediaBind = repeating: command: description: {
    action = exec command;
    inherit description;
    flags = {
      locked = true;
      inherit repeating;
    };
  };
  directions = ["left" "right" "up" "down"];
  workspaces = map toString (lib.range 1 9);

  defaultBinds =
    {
      "SUPER + slash" = bind ''hl.dsp.global("temple:keybinds")'' "Show keybinds";
      "SUPER + K" = bind ''hl.dsp.global("temple:palette")'' "Command palette";
      "SUPER + T" = bind ''hl.dsp.global("temple:themes")'' "Pick theme";
      "SUPER + L" = bind (exec "temple-lock") "Lock";
      "SUPER + Return" = bind (exec exe.terminal) "Terminal";
      "ALT + K" = bind (exec exe.terminal) "Terminal";
      "Print" = bind (exec "${exe.screenshot} region") "Screenshot a region";
      "SHIFT + Print" = bind (exec "${exe.screenshot} screen") "Screenshot every screen";
      "XF86AudioRaiseVolume" = mediaBind true "${exe.wpctl} set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+" "Volume up";
      "XF86AudioLowerVolume" = mediaBind true "${exe.wpctl} set-volume @DEFAULT_AUDIO_SINK@ 5%-" "Volume down";
      "XF86AudioMute" = mediaBind false "${exe.wpctl} set-mute @DEFAULT_AUDIO_SINK@ toggle" "Mute";
      "XF86AudioMicMute" = mediaBind false "${exe.wpctl} set-mute @DEFAULT_AUDIO_SOURCE@ toggle" "Mute microphone";
      "XF86AudioPlay" = mediaBind false "${exe.playerctl} play-pause" "Play or pause";
      "XF86AudioPause" = mediaBind false "${exe.playerctl} play-pause" "Play or pause";
      "XF86AudioNext" = mediaBind false "${exe.playerctl} next" "Next track";
      "XF86AudioPrev" = mediaBind false "${exe.playerctl} previous" "Previous track";
      "XF86MonBrightnessUp" = mediaBind true "${exe.brightnessctl} set 5%+" "Brightness up";
      "XF86MonBrightnessDown" = mediaBind true "${exe.brightnessctl} set 5%-" "Brightness down";
      "SUPER + E" = bind (exec "dolphin") "Files";
      "SUPER + Q" = bind "hl.dsp.window.close()" "Close window";
      "SUPER + F" = bind "hl.dsp.window.fullscreen()" "Fullscreen";
      "SUPER + Up" = bind ''hl.dsp.window.fullscreen({ mode = "maximized", action = "set" })'' "Maximize";
      "SUPER + Down" = bind ''hl.dsp.window.fullscreen({ mode = "maximized", action = "unset" })'' "Restore";
      "SUPER + V" = bind "hl.dsp.window.float()" "Toggle floating";
      "SUPER + Left" = bind ''hl.dsp.window.move({ direction = "left" })'' "Move window left";
      "SUPER + Right" = bind ''hl.dsp.window.move({ direction = "right" })'' "Move window right";
      "SUPER + SHIFT + Left" = bind ''hl.dsp.window.move({ monitor = "-1" })'' "Send window to previous monitor";
      "SUPER + SHIFT + Right" = bind ''hl.dsp.window.move({ monitor = "+1" })'' "Send window to next monitor";
      "SUPER + SHIFT + Up" = bind ''hl.dsp.window.move({ direction = "up" })'' "Move window up";
      "SUPER + SHIFT + Down" = bind ''hl.dsp.window.move({ direction = "down" })'' "Move window down";
      "SUPER + SHIFT + R" = bind (exec "hyprctl reload") "Reload Hyprland config";
      "SUPER + SHIFT + M" = bind "hl.dsp.exit()" "Exit Temple";
      "ALT + Tab" = bind (cycle true) "Next window";
      "ALT + SHIFT + Tab" = bind (cycle false) "Previous window";
    }
    // lib.genAttrs' directions (d: lib.nameValuePair (bindKey ["SUPER" "CTRL"] (lib.toSentenceCase d)) (bind ''hl.dsp.focus({ direction = "${d}" })'' "Focus ${d}"))
    // lib.genAttrs' workspaces (i: lib.nameValuePair (bindKey ["SUPER"] i) (bind "hl.dsp.focus({ workspace = ${i} })" "Workspace ${i}"))
    // lib.genAttrs' workspaces (i: lib.nameValuePair (bindKey ["SUPER" "SHIFT"] i) (bind "hl.dsp.window.move({ workspace = ${i} })" "Send window to workspace ${i}"));

  # Hyprland matches keysyms case-insensitively, so `Meta+left` and `SUPER + Left` are one bind.
  userKeys = lib.mapAttrs (id: bind: hyprlandKey id bind.key) keybinds;
  userKeysLower = map lib.toLower (lib.attrValues userKeys);
  duplicateKeys = lib.filter (key: lib.count (k: k == key) userKeysLower > 1) (lib.unique userKeysLower);
  userBinds = lib.mapAttrs' (id: user: lib.nameValuePair userKeys.${id} (bind (exec user.command) (lib.defaultTo user.command user.description))) keybinds;

  binds =
    if duplicateKeys != []
    then throw "temple.keybinds: more than one bind uses ${lib.concatStringsSep ", " duplicateKeys}"
    else lib.filterAttrs (key: _: !(lib.elem (lib.toLower key) userKeysLower)) defaultBinds // userBinds;

  mouseBinds = {
    "SUPER + mouse:272" = bind "hl.dsp.window.drag()" "Move window with the mouse" // {flags.mouse = true;};
    "SUPER + mouse:273" = bind "hl.dsp.window.resize()" "Resize window with the mouse" // {flags.mouse = true;};
  };

  displayKey = key:
    lib.replaceStrings
    ["SUPER" "CTRL" "ALT" "SHIFT" "slash" "mouse:272" "mouse:273" "Return" "XF86" "_"]
    ["Super" "Ctrl" "Alt" "Shift" "/" "Left drag" "Right drag" "Enter" "" " "]
    key;

  luaValue = value:
    if builtins.isBool value
    then lib.boolToString value
    else builtins.toJSON value;
  bindOptions = b: "{ ${lib.concatStringsSep ", " (lib.mapAttrsToList (name: value: "${name} = ${luaValue value}") ({inherit (b) description;} // b.flags))} }";

  rgba = hex: let
    digits = lib.removePrefix "#" hex;
  in "rgba(${digits}${lib.optionalString (builtins.stringLength digits == 6) "ff"})";
  gradient = colors:
    if builtins.length colors == 1
    then builtins.toJSON (rgba (builtins.head colors))
    else "{ colors = { ${lib.concatMapStringsSep ", " (c: builtins.toJSON (rgba c)) colors} }, angle = 45 }";
in {
  keybinds = lib.mapAttrsToList (key: b: {
    key = displayKey key;
    inherit (b) description;
  }) (binds // mouseBinds);

  # Hyprland options a theme owns. The main config runs this file at start
  # and reload, and temple-apply-theme evaluates it in the running compositor.
  themeLua = theme: ''
    hl.config({
      general = {
        border_size = ${toString theme.window.border},
        col = {
          active_border = ${gradient theme.window.active},
          inactive_border = ${gradient theme.window.inactive},
        },
      },
      decoration = {
        rounding = ${toString theme.radius},
        blur = { enabled = ${lib.boolToString (theme.glass.blur > 0)}, size = ${toString theme.glass.blur}, passes = 3, vibrancy = 0.2 },
      },
      misc = { background_color = 0xff${lib.removePrefix "#" theme.palette.base00} },
    })
  '';

  lua = ''
    ${lib.concatMapStringsSep "\n" monitorRule monitors}

    hl.env("XCURSOR_THEME", "breeze_cursors")
    hl.env("XCURSOR_SIZE", "24")
    hl.env("QT_QPA_PLATFORM", "wayland")
    hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")

    hl.config({
      general = {
        gaps_in = 6,
        gaps_out = 12,
        layout = "dwindle",
      },
      decoration = {
        shadow = { enabled = true, range = 24, render_power = 3, color = 0x66000000 },
      },
      animations = { enabled = true },
      dwindle = { preserve_split = true },
      misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        force_default_wallpaper = 0,
      },
      ecosystem = { no_update_news = true },
      input = { kb_layout = ${builtins.toJSON input.layout}, follow_mouse = 1 },
    })

    dofile(os.getenv("HOME") .. "/.local/state/temple/theme/hyprland.lua")

    hl.curve("temple", { type = "bezier", points = { { 0.2, 0.9 }, { 0.1, 1 } } })
    hl.animation({ leaf = "windows", enabled = true, speed = 1, bezier = "temple", style = "popin 95%" })
    hl.animation({ leaf = "windowsMove", enabled = true, speed = 1, bezier = "temple" })
    hl.animation({ leaf = "fade", enabled = true, speed = 1, bezier = "temple" })
    hl.animation({ leaf = "layers", enabled = true, speed = 1, bezier = "temple", style = "fade" })
    hl.animation({ leaf = "workspaces", enabled = true, speed = 1, bezier = "temple", style = "fade" })

    hl.layer_rule({ name = "temple-glass", match = { namespace = "^temple-" }, blur = true, ignore_alpha = 0.3 })

    hl.on("hyprland.start", function()
      hl.exec_cmd("qs -p /etc/temple/shell")
    end)

    ${lib.concatStringsSep "\n" (lib.mapAttrsToList (key: b: "hl.bind(${builtins.toJSON key}, ${b.action}, ${bindOptions b})") (binds // mouseBinds))}
  '';
}
