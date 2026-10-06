{
  flake.themes = {
    xp = import ./xp.nix;
    xp-luna = import ./xp-luna.nix;
    win7-black = import ./win7-black.nix;
    win7-aero = import ./win7-aero.nix;
    macos-sequoia = import ./macos-sequoia.nix;
    macos-tahoe = import ./macos-tahoe.nix;
    templeos = import ./templeos.nix;
  };
}
