# One window decoration and one Alt+Tab switcher per Temple theme, as KWin
# packages named temple-<theme>. Each package is the shared QML in ./kwin plus
# a Tokens.qml with that theme's values.
{
  lib,
  runCommand,
  writeText,
  themes,
}: let
  # Themes write #RRGGBBAA; QML reads 8 digits as #AARRGGBB.
  qmlColour = hex:
    if builtins.stringLength hex == 9
    then "#" + builtins.substring 7 2 hex + builtins.substring 1 6 hex
    else hex;

  tokens = theme: let
    t = theme.window.titlebar;
    colour = name: value: "    readonly property color ${name}: ${builtins.toJSON (qmlColour value)}";
  in
    writeText "Tokens.qml" ''
      import QtQuick

      QtObject {
      ${lib.concatStringsSep "\n" [
        (colour "titleColor" t.color)
        (colour "titleText" t.text)
        (colour "buttonText" t.buttonText)
        (colour "close" t.close)
        (colour "closeText" t.closeText)
        (colour "minimize" t.minimize)
        (colour "maximize" t.maximize)
        (colour "activeFrom" (lib.head theme.window.active))
        (colour "activeTo" (lib.last theme.window.active))
        (colour "inactiveFrom" (lib.head theme.window.inactive))
        (colour "inactiveTo" (lib.last theme.window.inactive))
        (colour "surface" theme.glass.tint)
        (colour "panelBorder" theme.glass.border)
        (colour "selection" theme.palette.base02)
        (colour "accent" theme.accent)
        (colour "text" theme.palette.base05)
      ]}
          readonly property bool buttonsLeft: ${lib.boolToString (t.align == "left")}
          readonly property int border: ${toString theme.window.border}
          readonly property int rounding: ${toString theme.window.rounding}
          readonly property int radius: ${toString theme.radius}
          readonly property real panelOpacity: ${toString (lib.min (theme.glass.opacity + 0.15) 1)}
          readonly property string fontSans: ${builtins.toJSON theme.font.sans}
          readonly property int fontSize: ${toString theme.font.size}
      }
    '';

  metadata = structure: name: theme:
    writeText "metadata.json" (builtins.toJSON {
      KPackageStructure = structure;
      KPlugin = {
        Id = "temple-${name}";
        Name = "Temple ${theme.label}";
        Description = "The ${theme.label} theme of v3x temple";
        License = "GPL";
      };
    });

  package = dir: structure: qml: name: theme: ''
    install -Dm444 ${metadata structure name theme} $out/share/kwin/${dir}/temple-${name}/metadata.json
    install -Dm444 ${qml} $out/share/kwin/${dir}/temple-${name}/contents/ui/main.qml
    install -Dm444 ${tokens theme} $out/share/kwin/${dir}/temple-${name}/contents/ui/Tokens.qml
  '';
in
  runCommand "temple-kwin" {} (lib.concatStrings (lib.mapAttrsToList (name: theme:
    package "decorations" "KWin/Decoration" ./kwin/decoration/main.qml name theme
    + package "tabbox" "KWin/WindowSwitcher" ./kwin/switcher/main.qml name theme)
  themes))
