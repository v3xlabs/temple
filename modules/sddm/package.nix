{pkgs}:
pkgs.stdenvNoCC.mkDerivation {
  pname = "temple-sddm-theme";
  version = "0.1.0";
  src = ./.;
  dontBuild = true;
  installPhase = ''
    theme=$out/share/sddm/themes/temple-xp
    mkdir -p $theme
    cp *.qml metadata.desktop theme.conf $theme/
    cp -r assets $theme/assets
    cp ${../../docs/public/logo.svg} $theme/logo.svg
  '';
  meta = {
    description = "XP-inspired Temple sign-in screen for SDDM 0.21 and Qt 6";
    license = pkgs.lib.licenses.mit;
    platforms = pkgs.lib.platforms.linux;
  };
}
