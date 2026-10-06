# Aero glass over a dark base.
let
  tint = "#0d1620";
in {
  label = "Windows 7 Black";
  style = "win7";
  edge = "bottom";
  palette = {
    base00 = "#141a22";
    base01 = "#1c2430";
    base02 = "#2a3646";
    base03 = "#4a5868";
    base04 = "#9aa8b8";
    base05 = "#e6edf5";
    base06 = "#f2f6fa";
    base07 = "#ffffff";
    base08 = "#e81123";
    base09 = "#ff8c00";
    base0A = "#ffb900";
    base0B = "#6fc33f";
    base0C = "#4ac8e8";
    base0D = "#3a96dd";
    base0E = "#c27cf2";
    base0F = "#a0522d";
  };
  accent = "#3a96dd";
  glass = {
    tint = "#101820";
    opacity = 0.55;
    blur = 20;
    border = "#ffffff33";
  };
  radius = 6;
  font = {
    sans = "Open Sans";
    mono = "Hack Nerd Font";
    size = 12;
  };
  window = {
    border = 1;
    active = ["#6fa8dc88" "#2a5a8a88"];
    inactive = ["#3a4a5a55"];
    titlebar = {
      color = "#1c2733";
      text = "#e6edf5";
      button = "#2a3646";
      buttonText = "#e6edf5";
      close = "#c42b1c";
      closeText = "#ffffff";
    };
  };
  bar = {
    height = 40;
    inherit tint;
    opacity = 0.6;
    highlight = "#ffffff22";
    orbTop = "#4fa3e0";
    orbBottom = "#0b3d6b";
    buttonHover = "#ffffff1f";
    buttonActive = "#ffffff33";
    text = "#ffffff";
  };
  tray = {
    text = "#ffffff";
    textMuted = "#9aa8b8";
    hover = "#ffffff26";
    hoverBorder = "#ffffff40";
    hoverText = "#ffffff";
    link = "#7ec3ff";
    separator = "#ffffff30";
    accent = "#3a96dd";
    rowRadius = 3;
    iconTint = "#ffffff";
    hoverIconTint = "#ffffff";
    barIconTint = "#ffffff";
    barLabels = false;
    barHighlight = "#ffffff";
    # Flyouts and tips are the bar's glass tint at 88% and 95%.
    popup = {
      padding = 8;
      radius = 6;
      color = tint + "e0";
      border = "#ffffff40";
      sheen = "#ffffff22";
    };
    tip = {
      frame = "plain";
      paddingX = 6;
      paddingY = 4;
      radius = 3;
      color = tint + "f2";
      border = "#ffffff40";
    };
    button = {
      radius = 3;
      borderWidth = 1;
      border = "#ffffff60";
      borderHover = "#ffffff60";
      rest = ["#ffffff30" "#ffffff0a"];
      hover = ["#ffffff50" "#ffffff0a"];
      down = ["#ffffff50" "#00000030"];
      activeText = "#ffffff";
      activeIcon = "#ffffff";
    };
    radio = {
      fill = "#00000000";
      border = "#9aa8b8";
      borderHover = "#ffffff";
      dot = "#3a96dd";
    };
    network = {
      width = 300;
      title = "#ffffff";
      titleRule = true;
      check = "#3a96dd";
      checkHover = "#3a96dd";
      field = {
        radius = 3;
        color = "#2a3646";
        border = "#ffffff30";
      };
      banner = null;
      list = {
        color = "#00000000";
        border = "#00000000";
      };
      settingsLink = true;
    };
    volume = {
      width = 250;
      layout = "speaker";
      slider = {
        groove = "#0a0f16";
        grooveBorder = "#ffffff40";
        fill = "#3a96dd";
        ticks = 0;
        thumb = ["#f2f6fa" "#9fb2c8"];
        thumbBorder = "#202a36";
        thumbBorderHover = "#202a36";
      };
      output = "Output device";
      outputStrong = false;
      settingsLink = false;
      mixer = {
        color = "#00000030";
        border = "#ffffff20";
      };
    };
  };
  notifications = {
    popup = {
      layout = "toast";
      count = 4;
      width = 360;
      margin = 8;
      color = "#101820d9";
      border = "#ffffff40";
      sheen = "#ffffff1a";
      appName = "#9aa8b8";
      summary = "#ffffff";
      body = "#e6edf5";
    };
    center = {
      width = 360;
      inset = 1;
      color = "#1c2733f2";
      border = "#ffffff40";
      radius = 6;
      text = "#ffffff";
      muted = "#9aa8b8";
      hover = "#ffffff1f";
      separator = "#ffffff1a";
      header = "#00000000";
      headerText = "#ffffff";
      headerLine = "#00000000";
      headerRule = true;
      link = "#7cc4ff";
      bellTint = "#00000000";
      toggle = "switch";
    };
    button = {
      padding = 10;
      height = 22;
      radius = 3;
      borderWidth = 1;
      border = "#ffffff40";
      color = "#ffffff14";
      hover = "#ffffff26";
      pressed = "#ffffff33";
      glow = "#00000000";
      text = "#ffffff";
      textHover = "#ffffff";
    };
    close = {
      size = 20;
      radius = 3;
      borderWidth = 0;
      border = "#aca899";
      borderHover = "#ffffff";
      color = "#00000000";
      hover = "#c42b1c";
      glyph = "#ffffff";
      glyphHover = "#ffffff";
      glyphSize = 16;
    };
  };
}
