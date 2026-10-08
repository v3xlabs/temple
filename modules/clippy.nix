# Clippy, the Office Assistant, as clippy.js ships him: one sprite sheet and
# the animation table that cuts it into frames. Microsoft owns the artwork, so
# it is downloaded at build time and never kept in this repository.
{
  fetchFromGitHub,
  jq,
  runCommand,
}: let
  src = fetchFromGitHub {
    owner = "smore-inc";
    repo = "clippy.js";
    rev = "8bfd1f92c725c6bc3a435d538a77c3302b327c08";
    hash = "sha256-venrFR4HleofWZHRjaxc6eio9T0MLmmSReenMBS/tsA=";
  };
in
  runCommand "temple-clippy" {nativeBuildInputs = [jq];} ''
    mkdir $out
    cp ${src}/agents/Clippy/map.png $out/map.png
    # agent.js wraps the table in a JSONP call.
    sed -e "s/^clippy\.ready('Clippy', //" -e 's/);[[:space:]]*$//' ${src}/agents/Clippy/agent.js \
      | jq -c '{framesize, animations}' > $out/agent.json
  ''
