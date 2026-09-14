{self, ...}: {
  perSystem = {pkgs, ...}: {
    packages = {
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
