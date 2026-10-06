# Aero glass: the bar draws aero.msstyles bitmaps over a light blue tint. Everything else is Windows 7 Black.
let
  black = import ./win7-black.nix;
  tint = "#74b8fc";
in
  black
  // {
    label = "Windows 7 Aero";
    skin = "msstyles";
    bar =
      black.bar
      // {
        inherit tint;
        opacity = 0.42;
      };
    tray =
      black.tray
      // {
        popup = black.tray.popup // {color = tint + "e0";};
        tip = black.tray.tip // {color = tint + "f2";};
      };
  }
