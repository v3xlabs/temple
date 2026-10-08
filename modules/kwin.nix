# One window decoration and one Alt+Tab switcher per Temple theme, as KWin
# packages named temple-<theme>. Each package is the shared QML in ./kwin plus
# a Tokens.qml with that theme's values. XP themes draw their frame from the
# Luna visual style instead.
{
  lib,
  fetchurl,
  imagemagick,
  p7zip,
  runCommand,
  writeText,
  themes,
}: let
  # The Luna Blue window frame from XP's own luna.msstyles, cut into one PNG
  # per state. Microsoft owns these bitmaps, so they are extracted at build
  # time. Window.* in the style's NORMALBLUE_INI gives the frame counts: two
  # (active, inactive) for the frame parts, eight for buttons and glyphs
  # (normal, hot, pressed, disabled; then the same for an inactive window).
  # Magenta marks transparent pixels.
  luna = runCommand "luna-frame" {nativeBuildInputs = [p7zip imagemagick];} ''
    7z x -tPE -y -osrc ${fetchurl {
      url = "https://archive.org/download/winxpluna/Themes/Luna/luna.msstyles";
      hash = "sha256-3Y6G5afBnqn+DjSZK6vv5ZIFXWjrhll2PIMAVYyl3LQ=";
    }} >/dev/null
    cd src/.rsrc/BITMAP
    mkdir $out
    # cut <bitmap> <name> <frame width> <frame height> <frame names...>
    cut() {
      local bitmap=$1 name=$2 width=$3 height=$4 i=0
      shift 4
      for frame in "$@"; do
        magick BLUE_''${bitmap}_BMP.bmp -crop "''${width}x''${height}+0+$((i * height))" +repage -transparent '#ff00ff' "$out/$name-$frame.png"
        i=$((i + 1))
      done
    }
    cut FRAMECAPTION caption 66 29 active inactive
    cut FRAMEMAXIMIZED maximized 66 29 active inactive
    cut FRAMELEFT left 5 31 active inactive
    cut FRAMERIGHT right 5 31 active inactive
    cut FRAMEBOTTOM bottom 49 5 active inactive
    states="0 1 2 3 4 5 6 7"
    cut CAPTIONBUTTON button 21 21 $states
    cut CLOSEBUTTON close 21 21 $states
    for glyph in CLOSE MINIMIZE MAXIMIZE RESTORE; do
      cut ''${glyph}GLYPH "$(echo $glyph | tr A-Z a-z)-glyph" 13 13 $states
    done
  '';
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

  decoration = name: theme:
    if theme.style == "xp"
    then
      package "decorations" "KWin/Decoration" ./kwin/decoration-xp/main.qml name theme
      + "install -Dm444 -t $out/share/kwin/decorations/temple-${name}/contents/ui ${luna}/*.png\n"
    else package "decorations" "KWin/Decoration" ./kwin/decoration/main.qml name theme;
in
  runCommand "temple-kwin" {} (lib.concatStrings (lib.mapAttrsToList (name: theme:
    decoration name theme
    + package "tabbox" "KWin/WindowSwitcher" ./kwin/switcher/main.qml name theme)
  themes))
