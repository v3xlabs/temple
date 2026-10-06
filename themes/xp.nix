# Luna Blue. The UI follows the XP window face, the terminal follows the classic console.
{
  label = "Windows XP";
  style = "xp";
  edge = "bottom";
  palette = {
    base00 = "#ece9d8";
    base01 = "#f1efe2";
    base02 = "#c1d2ee";
    base03 = "#aca899";
    base04 = "#716f64";
    base05 = "#000000";
    base06 = "#000000";
    base07 = "#ffffff";
    base08 = "#c1272d";
    base09 = "#e07b00";
    base0A = "#c9a400";
    base0B = "#3c9a3c";
    base0C = "#0f8bed";
    base0D = "#0054e3";
    base0E = "#7b3fbf";
    base0F = "#8b5a2b";
  };
  terminal = {
    base00 = "#000000";
    base01 = "#000000";
    base02 = "#000080";
    base03 = "#808080";
    base04 = "#c0c0c0";
    base05 = "#c0c0c0";
    base06 = "#ffffff";
    base07 = "#ffffff";
    base08 = "#ff0000";
    base09 = "#ff8000";
    base0A = "#ffff00";
    base0B = "#00ff00";
    base0C = "#00ffff";
    base0D = "#3b78ff";
    base0E = "#ff00ff";
    base0F = "#808000";
  };
  accent = "#0054e3";
  glass = {
    tint = "#ece9d8";
    opacity = 1.0;
    blur = 0;
    border = "#0054e3";
  };
  radius = 8;
  font = {
    sans = "Tahoma";
    mono = "Hack Nerd Font";
    size = 12;
  };
  window = {
    border = 1;
    active = ["#0058ee" "#3a93ff"];
    inactive = ["#7a96df" "#a6b9e8"];
    titlebar = {
      color = "#0a5ae8";
      text = "#ffffff";
      button = "#3c81f3";
      buttonText = "#ffffff";
      close = "#e0583c";
      closeText = "#ffffff";
    };
  };
  bar = {
    height = 30;
    taskbarTop = "#3d83f5";
    taskbarMid = "#245edb";
    taskbarBottom = "#1941a5";
    startTop = "#4fb84f";
    startMid = "#3c9a3c";
    startBottom = "#2d7d2d";
    trayTop = "#1290e8";
    trayBottom = "#0c5fc7";
    trayBorder = "#0f3fa0";
    taskActive = "#1e4fb4";
    taskInactive = "#3c81f3";
    text = "#ffffff";
  };
  tray = {
    text = "#000000";
    textMuted = "#716f64";
    hover = "#316ac5";
    hoverBorder = "#00000000";
    hoverText = "#ffffff";
    link = "#0054e3";
    separator = "#aca899";
    accent = "#0054e3";
    rowRadius = 0;
    iconTint = "#00000000";
    hoverIconTint = "#ffffff";
    barIconTint = "#ffffff";
    barLabels = false;
    barHighlight = "#ffffff";
    popup = {
      padding = 8;
      radius = 0;
      color = "#ece9d8";
      border = "#0054e3";
      sheen = "#00000000";
    };
    tip = {
      frame = "plain";
      paddingX = 6;
      paddingY = 4;
      radius = 0;
      color = "#ffffe1";
      border = "#000000";
    };
    button = {
      radius = 3;
      borderWidth = 1;
      border = "#003c74";
      borderHover = "#e5a01a";
      rest = ["#ffffff" "#ece9d8"];
      hover = ["#ffffff" "#ece9d8"];
      down = ["#ffffff" "#cdcac3"];
      activeText = "#000000";
      activeIcon = "#00000000";
    };
    radio = {
      fill = "#ffffff";
      border = "#1c5180";
      borderHover = "#1c5180";
      dot = "#21a121";
    };
    network = {
      width = 320;
      title = "#215dc6";
      titleRule = false;
      check = "#21a121";
      checkHover = "#ffffff";
      field = {
        radius = 0;
        color = "#ffffff";
        border = "#7f9db9";
      };
      # The list sits under a Luna band in a white well, and the band replaces the status line.
      banner = {
        top = "#3d83f5";
        bottom = "#245edb";
        text = "#ffffff";
      };
      list = {
        color = "#ffffff";
        border = "#7f9db9";
      };
      settingsLink = true;
    };
    volume = {
      width = 220;
      layout = "trackbar";
      slider = {
        groove = "#ffffff";
        grooveBorder = "#9d9c99";
        fill = "#00000000";
        ticks = 11;
        tick = "#a0a0a0";
        thumb = ["#ffffff" "#dcdad0"];
        thumbBorder = "#7a8fae";
        thumbBorderHover = "#e5a01a";
      };
      checkbox = {
        fill = ["#dcdcd7" "#ffffff"];
        border = "#1c5180";
        check = "#21a121";
      };
      output = "Output device";
      outputStrong = false;
      settingsLink = true;
      mixer = null;
    };
  };
  notifications = {
    popup = {
      layout = "balloon";
      count = 1;
      width = 300;
      margin = 0;
      fill = "#ffffe1";
      stroke = "#000000";
      text = "#000000";
    };
    center = {
      width = 360;
      inset = 1;
      color = "#ffffff";
      border = "#0054e3";
      radius = 8;
      text = "#000000";
      muted = "#716f64";
      hover = "#c1d2ee";
      separator = "#e5e2d6";
      header = "#0a5ae8";
      headerText = "#ffffff";
      headerLine = "#3a93ff";
      headerRule = false;
      link = "#ffffff";
      bellTint = "#00000000";
      toggle = "checkbox";
      checkbox = {
        fill = "#ffffff";
        border = "#1c5180";
        check = "#21a121";
      };
    };
    button = {
      padding = 10;
      height = 22;
      radius = 3;
      borderWidth = 1;
      border = "#003c74";
      color = "#fbfbf8";
      hover = "#fbfbf8";
      pressed = "#e3e2da";
      glow = "#f8b330";
      text = "#000000";
      textHover = "#000000";
    };
    close = {
      size = 14;
      radius = 2;
      borderWidth = 1;
      border = "#aca899";
      borderHover = "#ffffff";
      color = "#00000000";
      hover = "#e0583c";
      glyph = "#000000";
      glyphHover = "#ffffff";
      glyphSize = 13;
    };
  };
}
