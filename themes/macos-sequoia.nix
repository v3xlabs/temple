# macOS Sequoia (15) in light mode, the last release before Liquid Glass:
# system colours of the light appearance, Terminal's Basic profile for kitty,
# traffic-light title bar buttons and a translucent menu bar.
let
  bar = {
    height = 24;
    tint = "#f6f6f6";
    opacity = 0.6;
    text = "#000000";
    hover = "#0000001f";
    itemRadius = 4;
    panel = "#f6f6f6";
    panelOpacity = 0.9;
    panelText = "#1d1d1f";
    panelMuted = "#86868b";
    edge = "#0000002e";
    specular = "#ffffff80";
    sheen = 0;
    menuRadius = 6;
    panelRadius = 12;
    bannerRadius = 14;
    dialogRadius = 12;
    selection = "#007aff";
    selectionText = "#ffffff";
    selectionRadius = 4;
    separator = "#0000001a";
  };
in
  import ./macos-flyouts.nix bar
  // {
    inherit bar;
    label = "macOS Sequoia";
    style = "macos";
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
    radius = 10;
    font = {
      sans = "SF Pro Text";
      mono = "SF Mono";
      size = 13;
    };
    window = {
      border = 1;
      rounding = 10;
      active = ["#00000040"];
      inactive = ["#00000026"];
      titlebar = {
        color = "#ececec";
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
