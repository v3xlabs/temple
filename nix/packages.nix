{self, ...}: {
  perSystem = {pkgs, ...}: {
    packages = {
      sddm-theme = import ../modules/sddm/package.nix {inherit pkgs;};
      shell = pkgs.stdenvNoCC.mkDerivation {
        name = "temple-shell";
        src = ../shell;
        installPhase = ''
          mkdir -p $out/share/temple
          cp -r . $out/share/temple/shell
        '';
      };

      vm = self.nixosConfigurations.vm.config.system.build.vm;
    };
  };
}
