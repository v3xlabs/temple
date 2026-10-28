{self, ...}: {
  flake.nixosModules.sddm = {
    config,
    lib,
    pkgs,
    ...
  }: {
    options.temple.sddm.enable = lib.mkEnableOption "Temple's XP-inspired SDDM sign-in screen";
    config = lib.mkIf config.temple.sddm.enable {
      services.displayManager.sddm = {
        enable = true;
        theme = "temple-xp";
        # The greeter draws the logo and icons from SVG files. Plasma adds this
        # plugin itself; without Plasma the greeter has none.
        extraPackages = [pkgs.kdePackages.qtsvg];
      };
      environment.systemPackages = [self.packages.${pkgs.stdenv.hostPlatform.system}.sddm-theme];
      # The theme sets its text in Tahoma, which Plasma does not provide.
      fonts.packages = [(pkgs.callPackage ../tahoma.nix {})];
    };
  };
}
