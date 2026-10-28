# Wine ships Tahoma under the LGPL. Only Tahoma is taken so Wine's Courier
# and Symbol do not shadow the fonts other apps resolve those names to.
{
  runCommand,
  wineWow64Packages,
}:
runCommand "tahoma" {} ''
  install -Dm444 -t $out/share/fonts/truetype ${wineWow64Packages.fonts}/share/fonts/truetype/tahoma{,bd}.ttf
''
