# macOS Tahoe (26) in light mode: Liquid Glass. The menu bar has no backing,
# menus, panels and banners are clear glass with a specular edge, and windows
# round their corners further.
let
  bar = {
    height = 24;
    tint = "#000000";
    opacity = 0;
    text = "#ffffff";
    hover = "#ffffff33";
    itemRadius = 11;
    panel = "#fafafa";
    panelOpacity = 0.74;
    panelText = "#1d1d1f";
    panelMuted = "#6e6e73";
    edge = "#ffffff59";
    specular = "#ffffffe6";
    sheen = 0.55;
    menuRadius = 14;
    panelRadius = 24;
    bannerRadius = 24;
    dialogRadius = 26;
    selection = "#007aff";
    selectionText = "#ffffff";
    selectionRadius = 9;
    separator = "#00000014";
  };
in
  import ./macos-flyouts.nix bar
  // {
    inherit bar;
    label = "macOS Tahoe";
    style = "macos";
    skin = "tahoe";
    edge = "top";
    palette = {
      base00 = "#f6f6f6";
      base01 = "#ececec";
      base02 = "#b3d7ff";
      base03 = "#c6c6c8";
      base04 = "#86868b";
      base05 = "#1d1d1f";
      base06 = "#000000";
      base07 = "#ffffff";
      base08 = "#ff3b30";
      base09 = "#ff9500";
      base0A = "#ffcc00";
      base0B = "#28cd41";
      base0C = "#55bef0";
      base0D = "#007aff";
      base0E = "#af52de";
      base0F = "#a2845e";
    };
    terminal = {
      base00 = "#ffffff";
      base01 = "#e5e5e5";
      base02 = "#b4d5fe";
      base03 = "#666666";
      base04 = "#bfbfbf";
      base05 = "#000000";
      base06 = "#000000";
      base07 = "#e5e5e5";
      base08 = "#990000";
      base09 = "#b26b00";
      base0A = "#999900";
      base0B = "#00a600";
      base0C = "#00a6b2";
      base0D = "#0000b2";
      base0E = "#b200b2";
      base0F = "#8a5a2b";
    };
    accent = "#007aff";
    glass = {
      tint = "#f6f6f6";
      opacity = 0.92;
      blur = 20;
      border = "#0000001f";
    };
    radius = 18;
    font = {
      sans = "SF Pro Text";
      mono = "SF Mono";
      size = 13;
    };
    window = {
      border = 1;
      rounding = 18;
      active = ["#00000033"];
      inactive = ["#0000001f"];
      titlebar = {
        color = "#f5f5f5";
        text = "#3c3c3c";
        align = "left";
        close = "#ff5f57";
        minimize = "#febc2e";
        maximize = "#28c840";
        # macOS shows the glyphs only under the pointer; transparent glyphs match the buttons at rest.
        closeText = "#00000000";
        button = "#febc2e";
        buttonText = "#00000000";
      };
    };
  }
