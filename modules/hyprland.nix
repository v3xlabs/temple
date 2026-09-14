{
  theme,
  lib,
  monitors,
  input,
  keybinds,
}: let
  rgba = hex: alpha: "rgba(${lib.removePrefix "#" hex}${alpha})";
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
  bind = action: description: {inherit action description;};
  directions = ["left" "right" "up" "down"];
  workspaces = map toString (lib.range 1 9);

  defaultBinds =
    {
      "SUPER + slash" = bind ''hl.dsp.global("temple:keybinds")'' "Show keybinds";
      "SUPER + K" = bind ''hl.dsp.global("temple:palette")'' "Command palette";
      "SUPER + L" = bind (exec "temple-lock") "Lock";
      "SUPER + Return" = bind (exec "kitty") "Terminal";
      "ALT + K" = bind (exec "kitty") "Terminal";
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
    "SUPER + mouse:272" = bind "hl.dsp.window.drag()" "Move window with the mouse";
    "SUPER + mouse:273" = bind "hl.dsp.window.resize()" "Resize window with the mouse";
  };

  displayKey = key:
    lib.replaceStrings
    ["SUPER" "CTRL" "ALT" "SHIFT" "slash" "mouse:272" "mouse:273" "Return" "_"]
    ["Super" "Ctrl" "Alt" "Shift" "/" "Left drag" "Right drag" "Enter" " "]
    key;
in {
  keybinds = lib.mapAttrsToList (key: b: {
    key = displayKey key;
    inherit (b) description;
  }) (binds // mouseBinds);

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
        border_size = 1,
        col = {
          active_border = "${rgba theme.accent "cc"}",
          inactive_border = "${rgba theme.palette.base02 "aa"}",
        },
        layout = "dwindle",
      },
      decoration = {
        rounding = ${toString theme.radius},
        shadow = { enabled = true, range = 24, render_power = 3, color = 0x66000000 },
        blur = { enabled = true, size = ${toString theme.glass.blur}, passes = 3, vibrancy = 0.2 },
      },
      animations = { enabled = true },
      dwindle = { preserve_split = true },
      misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        force_default_wallpaper = 0,
        background_color = 0xff${lib.removePrefix "#" theme.palette.base00},
      },
      ecosystem = { no_update_news = true },
      input = { kb_layout = ${builtins.toJSON input.layout}, follow_mouse = 1 },
    })

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

      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (key: b: "hl.bind(${builtins.toJSON key}, ${b.action}, { description = ${builtins.toJSON b.description} })") binds)}
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (key: b: "hl.bind(${builtins.toJSON key}, ${b.action}, { mouse = true, description = ${builtins.toJSON b.description} })") mouseBinds)}
  '';
}
