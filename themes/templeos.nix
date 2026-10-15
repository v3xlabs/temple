# TempleOS: the VGA palette of Adam/Gr/GrPalette.HC (gr_palette_std), blue text
# on white windows, a blue status line with white and yellow text.
{
  label = "TempleOS";
  style = "templeos";
  edge = "top";
  # Windows, flyouts and the notification centre sit in a text-mode border.
  frame = "text";
  # Separators are the 2 px strokes of the box-drawing glyphs.
  lineWidth = 2;
  palette = {
    base00 = "#ffffff";
    base01 = "#aaaaaa";
    base02 = "#55ffff";
    base03 = "#5555ff";
    base04 = "#555555";
    base05 = "#0000aa";
    base06 = "#000000";
    base07 = "#ffffff";
    base08 = "#aa0000";
    base09 = "#aa5500";
    base0A = "#ffff55";
    base0B = "#00aa00";
    base0C = "#00aaaa";
    base0D = "#0000aa";
    base0E = "#aa00aa";
    base0F = "#ff5555";
  };
  # kitty draws base00 as colour 0 and base07 as colour 15, so black and white
  # swap places to keep text readable on the white background. Colour 3 is
  # BROWN, the dark yellow of the VGA palette.
  terminal = {
    base00 = "#ffffff";
    base01 = "#ffffff";
    base02 = "#55ffff";
    base03 = "#555555";
    base04 = "#aaaaaa";
    base05 = "#0000aa";
    base06 = "#aaaaaa";
    base07 = "#000000";
    base08 = "#aa0000";
    base09 = "#ff5555";
    base0A = "#aa5500";
    base0B = "#00aa00";
    base0C = "#00aaaa";
    base0D = "#0000aa";
    base0E = "#aa00aa";
    base0F = "#ff5555";
  };
  accent = "#0000aa";
  glass = {
    tint = "#ffffff";
    opacity = 1.0;
    blur = 0;
    border = "#0000aa";
  };
  radius = 0;
  # Both families hold the same 8x8 glyphs. The shell gives sizes in pixels and
  # kitty in points, so each family is scaled to draw the cell at 16 px from 12.
  font = {
    sans = "TempleOS";
    mono = "TempleOS Term";
    size = 12;
    # The 8x8 glyphs stay sharp only at this size and smear when emboldened.
    bitmap = true;
  };
  window = {
    border = 2;
    active = ["#0000aa"];
    inactive = ["#5555ff"];
    titlebar = {
      color = "#ffffff";
      text = "#0000aa";
      button = "#ffffff";
      buttonText = "#0000aa";
      close = "#ffffff";
      closeText = "#0000aa";
    };
  };
  bar = {
    height = 16;
    color = "#0000aa";
    text = "#ffffff";
    highlight = "#ffff55";
  };
  tray = {
    text = "#0000aa";
    textMuted = "#555555";
    hover = "#0000aa";
    hoverBorder = "#00000000";
    hoverText = "#ffffff";
    link = "#aa0000";
    separator = "#0000aa";
    accent = "#0000aa";
    rowRadius = 0;
    iconTint = "#0000aa";
    hoverIconTint = "#ffffff";
    barIconTint = "#ffffff";
    # The status line writes Msg:, Net: and Vol: instead of icons.
    barLabels = true;
    barHighlight = "#ffff55";
    popup = {
      padding = 16;
      radius = 0;
      color = "#00000000";
      border = "#00000000";
      sheen = "#00000000";
      sheet = null;
    };
    tip = {
      frame = "text";
      paddingX = 16;
      paddingY = 16;
      radius = 0;
      color = "#ffffff";
      border = "#00000000";
    };
    # Hovered and pressed buttons turn to reverse video.
    button = {
      radius = 0;
      borderWidth = 2;
      border = "#0000aa";
      borderHover = "#0000aa";
      rest = ["#ffffff" "#ffffff"];
      hover = ["#0000aa" "#0000aa"];
      down = ["#0000aa" "#0000aa"];
      activeText = "#ffffff";
      activeIcon = "#ffffff";
    };
    radio = {
      fill = "#00000000";
      border = "#555555";
      borderHover = "#ffffff";
      dot = "#0000aa";
    };
    network = {
      # 24 text cells inside the border.
      width = 416;
      title = "#0000aa";
      titleRule = true;
      check = "#0000aa";
      checkHover = "#0000aa";
      field = {
        radius = 3;
        color = "#2a3646";
        border = "#0000aa";
      };
      banner = null;
      list = {
        color = "#00000000";
        border = "#00000000";
      };
      settingsLink = false;
    };
    volume = {
      # 20 text cells inside the border.
      width = 352;
      layout = "gauge";
      output = "Output device";
      outputStrong = false;
      settingsLink = false;
      mixer = null;
    };
  };
  notifications = {
    popup = {
      layout = "window";
      count = 4;
      width = 416;
      margin = 8;
      color = "#0000aa";
      critical = "#aa0000";
      background = "#ffffff";
    };
    center = {
      width = 512;
      inset = 16;
      color = "#ffffff";
      border = "#00000000";
      radius = 0;
      text = "#0000aa";
      muted = "#555555";
      hover = "#55ffff";
      separator = "#0000aa";
      header = "#00000000";
      headerText = "#0000aa";
      headerLine = "#00000000";
      headerRule = true;
      link = "#aa0000";
      bellTint = "#00000000";
      toggle = "text";
    };
    button = {
      padding = 16;
      height = 24;
      radius = 0;
      borderWidth = 2;
      border = "#0000aa";
      color = "#ffffff";
      hover = "#0000aa";
      pressed = "#0000aa";
      glow = "#00000000";
      text = "#0000aa";
      textHover = "#ffffff";
    };
    close = {
      size = 20;
      radius = 10;
      borderWidth = 0;
      border = "#aca899";
      borderHover = "#ffffff";
      color = "#00000000";
      hover = "#55ffff";
      glyph = "#555555";
      glyphHover = "#555555";
      glyphSize = 16;
    };
  };
}
