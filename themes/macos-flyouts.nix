# Tray flyouts and notifications of the macOS themes, drawn from each theme's bar tokens.
bar: {
  frame = "glass";
  tray = {
    text = bar.panelText;
    textMuted = bar.panelMuted;
    hover = "#00000014";
    hoverBorder = "#00000000";
    hoverText = bar.panelText;
    link = bar.selection;
    separator = bar.separator;
    accent = bar.selection;
    rowRadius = bar.selectionRadius;
    iconTint = bar.panelText;
    hoverIconTint = bar.panelText;
    barIconTint = bar.text;
    barLabels = false;
    barHighlight = bar.text;
    popup = {
      # Liquid Glass panels round their corners far enough to need wider insets.
      padding =
        if bar.panelRadius > 16
        then bar.panelRadius / 2
        else 8;
      radius = bar.panelRadius;
      color = "#00000000";
      border = "#00000000";
      sheen = "#00000000";
    };
    tip = {
      frame = "plain";
      paddingX = 6;
      paddingY = 4;
      radius = bar.selectionRadius + 2;
      color = bar.panel;
      border = "#00000026";
    };
    button = {
      radius = bar.selectionRadius + 1;
      borderWidth = 1;
      border = "#00000026";
      borderHover = "#00000026";
      rest = ["#ffffff" "#f6f6f6"];
      hover = ["#f8f8f8" "#f6f6f6"];
      down = ["#dcdcdc" "#d4d4d4"];
      activeText = bar.panelText;
      activeIcon = bar.panelText;
    };
    radio = {
      fill = "#00000000";
      border = bar.panelMuted;
      borderHover = bar.panelText;
      dot = bar.selection;
    };
    network = {
      width = 300;
      title = bar.panelText;
      titleRule = true;
      check = bar.selection;
      checkHover = bar.selection;
      field = {
        radius = bar.selectionRadius;
        color = "#ffffff";
        border = bar.separator;
      };
      banner = null;
      list = {
        color = "#00000000";
        border = "#00000000";
      };
      settingsLink = false;
    };
    volume = {
      width = 300;
      layout = "controlCenter";
      track = {
        color = "#0000001a";
        fill = "#ffffff";
        border = "#00000014";
      };
      output = "Output";
      outputStrong = true;
      settingsLink = false;
      mixer = null;
    };
  };
  notifications = {
    popup = {
      layout = "banner";
      count = 4;
      width = 360;
      margin = 8;
      radius = bar.bannerRadius;
      text = bar.panelText;
      muted = bar.panelMuted;
    };
    center = {
      width = 360;
      inset = 1;
      color = "#00000000";
      border = "#00000000";
      radius = bar.panelRadius;
      text = bar.panelText;
      muted = bar.panelMuted;
      hover = "#00000014";
      separator = bar.separator;
      header = "#00000000";
      headerText = bar.panelText;
      headerLine = "#00000000";
      headerRule = true;
      link = bar.selection;
      # The menu bar draws status items as monochrome glyphs in its text colour.
      bellTint = bar.text;
      toggle = "switch";
    };
    button = {
      padding = 10;
      height = 22;
      radius = 11;
      borderWidth = 1;
      border = "#0000001f";
      color = "#ffffff99";
      hover = "#ffffffe6";
      pressed = "#d9d9d9";
      glow = "#00000000";
      text = "#1d1d1f";
      textHover = "#1d1d1f";
    };
    close = {
      size = 20;
      radius = 10;
      borderWidth = 1;
      border = "#0000001f";
      borderHover = "#0000001f";
      color = "#f2f2f2";
      hover = "#ffffff";
      glyph = "#595959";
      glyphHover = "#595959";
      glyphSize = 14;
    };
  };
}
