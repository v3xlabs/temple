{
  lib,
  self,
  ...
}: {
  perSystem = {pkgs, ...}: let
    inherit (import ../tests/common.nix {inherit pkgs self;}) test;
  in {
    checks =
      {
        sddm-theme =
          pkgs.runCommand "temple-sddm-tests" {
            nativeBuildInputs = [pkgs.qt6.qtdeclarative];
            QT_QPA_PLATFORM = "offscreen";
            QT_QUICK_BACKEND = "software";
            NIXPKGS_QT6_QML_IMPORT_PATH = "${pkgs.qt6.qtdeclarative}/lib/qt-6/qml";
            # The theme draws its logo and icons from SVG files.
            QT_PLUGIN_PATH = "${pkgs.kdePackages.qtsvg}/lib/qt-6/plugins";
          } ''
            cp -r ${../.} source
            chmod -R u+w source
            status=0
            qmltestrunner -input source/tests/sddm > log 2>&1 || status=$?
            cat log
            test $status -eq 0
            if grep -q "Cannot open" log; then
              echo "the theme references an image that does not load" >&2
              exit 1
            fi
            touch $out
          '';
      }
      // lib.genAttrs ["sessions" "picker-screens" "pickers" "clippy" "startmenu" "clipboard" "health"] (name: import ../tests/${name}.nix {inherit pkgs test;});
  };
}
