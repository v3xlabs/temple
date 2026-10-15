# Aero glass over a light blue tint. Everything else is Windows 7 Black, whose flyouts are a white sheet in any glass.
let
  black = import ./win7-black.nix;
  tint = "#74b8fc";
in
  black
  // {
    label = "Windows 7 Aero";
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
      };
  }
