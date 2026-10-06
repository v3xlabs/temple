{
  flake.themes = {
    dark = import ./dark.nix;
    light = import ./light.nix;
    xp = import ./xp.nix;
    win7-dark = import ./win7-dark.nix;
  };
}
