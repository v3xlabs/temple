{
  description = "v3x temple: a KDE Plasma 6 desktop with a Quickshell shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux"];

      imports = [
        inputs.treefmt-nix.flakeModule
        ./nix/treefmt.nix
        ./nix/devshell.nix
        ./nix/packages.nix
        ./nix/checks.nix
        ./themes
        ./modules
        ./hosts
      ];
    };
}
