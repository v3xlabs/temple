# Bitmaps of XP's own luna.msstyles (Luna Blue), cut into PNGs at build time:
# Microsoft owns them, so they are never kept in this repository. The style's
# NORMALBLUE_INI names the bitmap, image count, sizing margins and transparent
# colour of each part; magenta marks transparent pixels unless the part names
# another colour, and 32-bit bitmaps carry straight alpha.
#
# frame/ holds the window frame for modules/kwin/decoration-xp. Window.* gives
# the frame counts: two (active, inactive) for the frame parts, eight for
# buttons and glyphs (normal, hot, pressed, disabled; then the same for an
# inactive window).
#
# startpanel/ holds the Start menu for shell/start/XpStartMenu.qml, from
# StartPanel.* and StartMenu::Toolbar.*.
{
  fetchurl,
  imagemagick,
  p7zip,
  runCommand,
}:
runCommand "temple-luna" {nativeBuildInputs = [p7zip imagemagick];} ''
  7z x -tPE -y -osrc ${fetchurl {
    url = "https://archive.org/download/winxpluna/Themes/Luna/luna.msstyles";
    hash = "sha256-3Y6G5afBnqn+DjSZK6vv5ZIFXWjrhll2PIMAVYyl3LQ=";
  }} >/dev/null
  cd src/.rsrc/BITMAP
  mkdir -p $out/frame $out/startpanel

  # cut <bitmap> <name> <frame width> <frame height> <frame names...>
  cut() {
    local bitmap=$1 name=$2 width=$3 height=$4 i=0
    shift 4
    for frame in "$@"; do
      magick BLUE_''${bitmap}_BMP.bmp -crop "''${width}x''${height}+0+$((i * height))" +repage -transparent '#ff00ff' "$out/frame/$name-$frame.png"
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

  # This header puts the pixels at byte 56; XP reads them from byte 54, right
  # after the header, and gets the blue that FillColorHint names.
  printf '\x36' | dd of=BLUE_STARTUSERPANEL_BMP.bmp bs=1 seek=10 conv=notrunc 2>/dev/null
  # png <bitmap> <name> [crop]
  png() {
    magick BLUE_''${1}_BMP.bmp ''${3:+-crop $3 +repage} -transparent '#ff00ff' "$out/startpanel/$2.png"
  }
  png STARTUSERPANEL userpane
  png USERTILEBACKGROUND usertile
  png STARTPANELMFUBACKGROUND proglist
  png STARTPROGRAMSSEPARATOR proglist-separator
  png STARTPANELMOREPROGBACKGROUND moreprograms
  png STARTPANELMOREPROGARROW moreprograms-arrow
  png STARTPANELMOREPROGARROWHOT moreprograms-arrow-hot
  png STARTPANELPLACESBACKGROUND placeslist
  png STARTPLACESSEPARATOR placeslist-separator
  png STARTPANELLOGOFFBACKGROUND logoff
  # Three 24px icons side by side: undock, log off, turn off.
  png STARTPANELLOGOFFBUTTONS logoff-button 24x24+24+0
  png STARTPANELLOGOFFBUTTONSHOT logoff-button-hot 24x24+24+0
  png STARTPANELLOGOFFBUTTONS turnoff-button 24x24+48+0
  png STARTPANELLOGOFFBUTTONSHOT turnoff-button-hot 24x24+48+0
  png STARTGROUPBACKGROUND programs
  # Three 8x2 states, normal (all transparent), hot and pressed; red marks
  # transparent pixels.
  for state in 1:hot 2:pressed; do
    magick BLUE_STARTGROUPTOOLBARBUTTON_BMP.bmp -crop "8x2+0+$((''${state%:*} * 2))" +repage -transparent '#ff0000' "$out/startpanel/programs-item-''${state#*:}.png"
  done
''
