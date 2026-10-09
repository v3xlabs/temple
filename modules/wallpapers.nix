# The default wallpapers of the systems the themes imitate, offered by the
# background picker. Microsoft and Apple own them, so they are downloaded at
# build time and never kept in this repository. File names are the labels the
# picker shows.
{
  fetchurl,
  fetchzip,
  runCommand,
}: let
  # XP shipped Bliss at 800x600; this is the 1920x1080 scan of the photograph.
  bliss = fetchurl {
    url = "https://archive.org/download/windows-bliss-wallpaper-pack/Bliss_OG%28DesktopWallpaper%29.png";
    hash = "sha256-sDH0/4Ztkk6uoI2Jrg/wLzSOLN1a1z+JRghrCwJcJ1U=";
  };
  xp = fetchzip {
    name = "xp-wallpapers";
    url = "https://archive.org/download/windows-xp-wallpapers_202210/WindowsXP_Wallpapers.zip";
    hash = "sha256-bGqnmW3lTQSovhamb/0B0vl1LZb4oqv1D/LWBEvoDaQ=";
    stripRoot = false;
  };
  win7 = fetchzip {
    name = "win7-wallpapers";
    url = "https://archive.org/download/windows-7-default-wallpapers/Windows%207%20Default%20Wallpapers.zip";
    hash = "sha256-q2iIa/GSI77l9xO7JrjKf4Us8sd/z70cJhpUW2svYcY=";
  };
  macos = name: hash:
    fetchurl {
      url = "https://media.512pixels.net/downloads/macos-wallpapers-6k/${name}";
      inherit hash;
    };
in
  runCommand "temple-wallpapers" {} ''
    mkdir $out
    cp ${bliss} "$out/Windows XP Bliss.png"
    for file in ${xp}/*.jpg; do
      cp "$file" "$out/Windows XP $(basename "$file")"
    done
    cp ${win7}/Windows/img0.jpg "$out/Windows 7 Harmony.jpg"
    for dir in Architecture Characters Landscapes Nature Scenes; do
      n=0
      for file in $(ls ${win7}/$dir/*.jpg | sort -V); do
        n=$((n + 1))
        cp "$file" "$out/Windows 7 $dir $n.jpg"
      done
    done
    cp ${macos "15-Sequoia-Light-6K.jpg" "sha256-kZW3sgIjS1G6gRabkkQb9DqoxXKAGjXd0oixqg3ipfk="} "$out/macOS Sequoia Light.jpg"
    cp ${macos "15-Sequoia-Dark-6K.jpg" "sha256-yZ1lt4J9Ri0MU+GOXTbLfBh/oXJvkL7lgxrpDdkxitY="} "$out/macOS Sequoia Dark.jpg"
    cp ${macos "26-Tahoe-Light-6K.png" "sha256-KapXpD+XKrKKCCADHN5ZjRoy7V5w/oQYsONeN8s4J7Q="} "$out/macOS Tahoe Light.png"
    cp ${macos "26-Tahoe-Dark-6K.png" "sha256-hqK2hKMbAtwS8FSvSNBh6cLsC48S+GmSas5kyD9QGNs="} "$out/macOS Tahoe Dark.png"
  ''
