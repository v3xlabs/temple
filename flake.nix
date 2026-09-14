{
  description = "v3x temple: a Wayland desktop built on Hyprland and Quickshell";

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
        ./themes
        ./modules
        ./hosts
      ];
    };
}
