{
  lib,
  self,
  ...
}: {
  perSystem = {pkgs, ...}: let
    inherit (import ../tests/common.nix {inherit pkgs self;}) test;
  in {
    checks = lib.genAttrs ["sessions" "picker-screens" "pickers" "clippy" "startmenu" "clipboard" "health"] (name: import ../tests/${name}.nix {inherit pkgs test;});
  };
}
