# Aero glass over a dark base.
{
  label = "Windows 7 Dark";
  variant = "dark";
  style = "win7";
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
    border = 2;
    active = ["#6fa8dcaa" "#2a5a8aaa"];
    inactive = ["#3a4a5a88"];
  };
  bar = {
    height = 40;
    tint = "#0d1620";
    opacity = 0.6;
    highlight = "#ffffff22";
    orbTop = "#4fa3e0";
    orbBottom = "#0b3d6b";
    buttonHover = "#ffffff1f";
    buttonActive = "#ffffff33";
    text = "#ffffff";
  };
}
