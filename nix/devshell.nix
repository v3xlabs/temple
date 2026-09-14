{
  perSystem = {pkgs, ...}: {
    devShells.default = pkgs.mkShell {
      packages = [
        pkgs.just
        pkgs.quickshell
        pkgs.alejandra
      ];
    };
  };
}
