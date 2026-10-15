# The aero.msstyles bar and Aero glass over a dark tint.
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
    text = "#ffffff";
  };
  # Windows 7 draws its flyouts as a white sheet inside the glass frame, whatever
  # the glass colour, so the flyout tokens are the sheet's. The frame is the bar's
  # glass tint at 88%.
  tray = {
    text = "#000000";
    textMuted = "#6d6d6d";
    hover = "#e5f3fb";
    hoverBorder = "#a8cff5";
    hoverText = "#000000";
    link = "#0066cc";
    separator = "#d5dfe5";
    accent = "#3399ff";
    rowRadius = 3;
    iconTint = "#00000000";
    hoverIconTint = "#00000000";
    barIconTint = "#ffffff";
    barLabels = false;
    barHighlight = "#ffffff";
    popup = {
      padding = 14;
      radius = 6;
      color = tint + "e0";
      border = "#ffffff40";
      sheen = "#ffffff22";
      # The sheet sits this far inside the frame, edged by a dark line.
      sheet = {
        inset = 6;
        color = "#ffffff";
        border = "#80435d6d";
      };
    };
    tip = {
      frame = "plain";
      paddingX = 6;
      paddingY = 4;
      radius = 2;
      color = "#f4f6fb";
      border = "#767676";
    };
    button = {
      radius = 3;
      borderWidth = 1;
      border = "#707070";
      borderHover = "#3c7fb1";
      rest = ["#f2f2f2" "#cfcfcf"];
      hover = ["#eaf6fd" "#a7d9f5"];
      down = ["#c4e5f6" "#6ebee8"];
      activeText = "#000000";
      activeIcon = "#00000000";
    };
    radio = {
      fill = "#f4f4f4";
      border = "#8e8f8f";
      borderHover = "#3c7fb1";
      dot = "#1e64c8";
    };
    network = {
      width = 312;
      title = "#1e395b";
      titleRule = true;
      check = "#3399ff";
      checkHover = "#3399ff";
      field = {
        radius = 2;
        color = "#ffffff";
        border = "#abadb3";
      };
      banner = null;
      list = {
        color = "#00000000";
        border = "#00000000";
      };
      settingsLink = true;
    };
    volume = {
      width = 262;
      layout = "speaker";
      slider = {
        groove = "#e7eaea";
        grooveBorder = "#b0b0b0";
        fill = "#3399ff";
        ticks = 0;
        thumb = ["#f2f6fa" "#9fb2c8"];
        thumbBorder = "#707070";
        thumbBorderHover = "#3c7fb1";
      };
      output = "Output device";
      outputStrong = false;
      settingsLink = false;
      # The footer strip Windows 7 puts under its flyouts.
      mixer = {
        color = "#f1f5fb";
        border = "#ccd9ea";
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
