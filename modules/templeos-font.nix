# TempleOS is public domain. The font is the 8x8 `sys_font_std` table from Kernel/FontStd.HC.
{
  fetchFromGitHub,
  python3,
  runCommand,
}: let
  source = fetchFromGitHub {
    owner = "cia-foundation";
    repo = "TempleOS";
    rev = "c26482bb6ad3f80106d28504ec5db3c6a360732c";
    hash = "sha256-+hb+6P+SelN2CKu4geIdviqGtIwbAsKalNRJSgYXfHU=";
  };
in
  runCommand "templeos-font" {nativeBuildInputs = [(python3.withPackages (ps: [ps.fonttools]))];} ''
    mkdir -p $out/share/fonts/truetype
    python3 ${./templeos-font.py} ${source}/Kernel/FontStd.HC $out/share/fonts/truetype
  ''
