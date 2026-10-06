{
  lib,
  monitors,
  input,
  keybinds,
  exe,
  autostart,
  hyprbars,
  titlebarExclude,
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
      "SUPER + Down" = bind "temple.down" "Restore, then minimize";
      "SUPER + V" = bind "hl.dsp.window.float()" "Toggle tiling";
      "SUPER + Left" = bind "temple.snap(-1)" "Snap window left";
      "SUPER + Right" = bind "temple.snap(1)" "Snap window right";
      "SUPER + SHIFT + Left" = bind ''hl.dsp.window.move({ monitor = "l" })'' "Send window to the screen on the left";
      "SUPER + SHIFT + Right" = bind ''hl.dsp.window.move({ monitor = "r" })'' "Send window to the screen on the right";
      "SUPER + SHIFT + Up" = bind ''hl.dsp.window.move({ monitor = "u" })'' "Send window to the screen above";
      "SUPER + SHIFT + Down" = bind ''hl.dsp.window.move({ monitor = "d" })'' "Send window to the screen below";
      "SUPER + SHIFT + R" = bind (exec "hyprctl reload") "Reload Hyprland config";
      "SUPER + SHIFT + M" = bind "hl.dsp.exit()" "Exit Temple";
      "ALT + Tab" = bind ''hl.dsp.global("temple:switcher-next")'' "Switch to the next window";
      "ALT + SHIFT + Tab" = bind ''hl.dsp.global("temple:switcher-previous")'' "Switch to the previous window";
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

  # A bare modifier press reaches the shell, which lists the binds that start
  # with it. Non-consuming keeps the modifier working everywhere. Releases come
  # from the key hook in the main config instead.
  hintBinds = let
    hint = name:
      bind ''hl.dsp.global("temple:hint-${name}")'' "Key hint"
      // {flags.non_consuming = true;};
  in {
    "Super_L" = hint "super";
    "Super_R" = hint "super";
    "Alt_L" = hint "alt";
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

  # Hyprland options a theme owns. The main config runs this file at start and
  # on every reload; temple-apply-theme switches themes with a reload, because
  # title bar buttons can only be added, and a reload clears them first.
  themeLua = theme: let
    t = theme.window.titlebar;
    button = bg: fg: icon: action: "hl.plugin.hyprbars.add_button({ bg_color = ${builtins.toJSON (rgba bg)}, fg_color = ${builtins.toJSON (rgba fg)}, size = 16, icon = ${builtins.toJSON icon}, action = ${builtins.toJSON action} })";
    eval = code: "hyprctl eval '${code}'";
  in ''
    hl.config({
      general = {
        border_size = ${toString theme.window.border},
        col = {
          active_border = ${gradient theme.window.active},
          inactive_border = ${gradient theme.window.inactive},
        },
      },
      decoration = {
        blur = { enabled = ${lib.boolToString (theme.glass.blur > 0)}, size = ${toString theme.glass.blur}, passes = 3, vibrancy = 0.2 },
      },
      misc = { background_color = 0xff${lib.removePrefix "#" theme.palette.base00} },
    })

    -- The title bar plugin loads after the first parse, which then runs again.
    if hl.plugin.hyprbars then
      hl.config({
        plugin = {
          hyprbars = {
            bar_height = 26,
            bar_color = ${builtins.toJSON (rgba t.color)},
            bar_text_font = ${builtins.toJSON theme.font.sans},
            bar_text_size = ${toString (theme.font.size - 1)},
            bar_buttons_alignment = "right",
            bar_part_of_window = true,
            bar_precedence_over_border = true,
            on_double_click = ${builtins.toJSON (eval ''hl.dispatch(hl.dsp.window.fullscreen({ mode = "maximized" }))'')},
            col = { text = ${builtins.toJSON (rgba t.text)} },
          },
        },
      })
      -- The first button added sits furthest right.
      ${button t.close t.closeText "×" (eval "hl.dispatch(hl.dsp.window.close())")}
      ${button t.button t.buttonText "□" (eval ''hl.dispatch(hl.dsp.window.fullscreen({ mode = "maximized" }))'')}
      ${button t.button t.buttonText "–" (eval "temple.minimize(hl.get_active_window().address)")}
    end
  '';

  lua = ''
    ${lib.concatMapStringsSep "\n" monitorRule monitors}

    hl.env("XCURSOR_THEME", "breeze_cursors")
    hl.env("XCURSOR_SIZE", "24")
    hl.env("QS_ICON_THEME", "breeze")
    hl.env("QT_QPA_PLATFORM", "wayland")
    hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")

    hl.config({
      general = {
        gaps_in = 0,
        gaps_out = 0,
        -- Borders are 1px, so the grab area reaches past them to stay easy to hit.
        resize_on_border = true,
        extend_border_grab_area = 10,
        hover_icon_on_border = true,
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
      input = { kb_layout = ${builtins.toJSON input.layout}, follow_mouse = 2 },
    })

    -- Hyprland loads the listed plugins after each parse and unloads any no longer listed.
    hl.plugin.load("${hyprbars}/lib/libhyprbars.so")
    -- Apps that draw their own title bar.
    if hl.plugin.hyprbars then
      hl.window_rule({ name = "temple-own-titlebar", match = { class = ${builtins.toJSON "^(${lib.concatStringsSep "|" titlebarExclude})$"} }, ["hyprbars:no_bar"] = true })
    end

    dofile(os.getenv("HOME") .. "/.local/state/temple/theme/hyprland.lua")

    hl.curve("temple", { type = "bezier", points = { { 0.2, 0.9 }, { 0.1, 1 } } })
    hl.animation({ leaf = "windows", enabled = true, speed = 1, bezier = "temple", style = "popin 95%" })
    hl.animation({ leaf = "windowsMove", enabled = true, speed = 1, bezier = "temple" })
    hl.animation({ leaf = "fade", enabled = true, speed = 1, bezier = "temple" })
    hl.animation({ leaf = "layers", enabled = true, speed = 1, bezier = "temple", style = "fade" })
    hl.animation({ leaf = "workspaces", enabled = true, speed = 1, bezier = "temple", style = "fade" })

    hl.layer_rule({ name = "temple-glass", match = { namespace = "^temple-" }, blur = true, ignore_alpha = 0.3 })

    ${builtins.readFile ./windows.lua}

    -- Binds cannot report a modifier coming up after a combo such as Alt+Tab,
    -- so every Alt and Super release goes to the shell (key hint, Alt+Tab).
    -- Keycodes are evdev + 8: 64 Alt_L, 133 Super_L, 134 Super_R.
    local temple_modifiers = { [64] = "alt", [133] = "super", [134] = "super" }
    hl.on("input.keyboard.key", function(keycode, _, state)
      local modifier = temple_modifiers[keycode]
      if modifier and state == 0 then
        hl.dispatch(hl.dsp.global("temple:released-" .. modifier))
      end
    end)

    hl.on("hyprland.start", function()
      hl.exec_cmd("qs -p /etc/temple/shell")
      ${lib.concatMapStringsSep "\n      " (command: "hl.exec_cmd(${builtins.toJSON command})") autostart}
    end)

    ${lib.concatStringsSep "\n" (lib.mapAttrsToList (key: b: "hl.bind(${builtins.toJSON key}, ${b.action}, ${bindOptions b})") (binds // mouseBinds // hintBinds))}
  '';
}
