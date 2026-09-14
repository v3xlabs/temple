{
  perSystem = {
    treefmt = {
      projectRootFile = "flake.nix";
      programs.alejandra.enable = true;
      programs.qmlformat.enable = true;
    };
  };
}
