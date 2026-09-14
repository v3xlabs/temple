{theme}: let
  p = theme.palette;
in ''
  font_family ${theme.font.mono}
  font_size ${toString theme.font.size}
  background_opacity ${toString theme.glass.opacity}
  window_padding_width 10
  enable_audio_bell no
  confirm_os_window_close 0

  background ${p.base00}
  foreground ${p.base05}
  cursor ${p.base05}
  selection_background ${p.base02}
  selection_foreground ${p.base05}

  color0 ${p.base00}
  color8 ${p.base03}
  color1 ${p.base08}
  color9 ${p.base08}
  color2 ${p.base0B}
  color10 ${p.base0B}
  color3 ${p.base0A}
  color11 ${p.base0A}
  color4 ${p.base0D}
  color12 ${p.base0D}
  color5 ${p.base0E}
  color13 ${p.base0E}
  color6 ${p.base0C}
  color14 ${p.base0C}
  color7 ${p.base05}
  color15 ${p.base07}
''
