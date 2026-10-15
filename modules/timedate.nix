# The world map of XP's Date and Time Properties, bitmap 50 of timedate.cpl,
# for the Time Zone tab of shell/clock/XpDateTime.qml. The cabinet comes from
# an XP SP3 install image at build time: Microsoft owns the bitmap, so it is
# never kept in this repository.
{
  fetchurl,
  imagemagick,
  p7zip,
  runCommand,
}:
runCommand "temple-timedate" {nativeBuildInputs = [p7zip imagemagick];} ''
  # The cabinet holds timedate.cpl under the cabinet's own name, TIMEDATE.CP_.
  7z e -y ${fetchurl {
    name = "timedate.cab";
    url = "https://archive.org/download/WinXPProSP3x86FullyUpdated/GRTMPVOL_EN_noNetFx_v1.iso/I386%2FTIMEDATE.CP_";
    hash = "sha256-3oxAqiXE66Gr6ZaWODZ9y6uQWqu0oh5xmwStFJRD7vU=";
  }} >/dev/null
  7z e -y -tPE TIMEDATE.CP_ .rsrc/BITMAP/50.bmp >/dev/null
  mkdir $out
  magick 50.bmp $out/worldmap.png
''
