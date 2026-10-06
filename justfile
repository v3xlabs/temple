default:
    @just --list

# Build and boot the Temple VM (login: temple / temple, autologin into the Temple session)
vm:
    nix run path:.#vm

# Build the VM without booting it
build:
    nix build path:.#vm

# Run this checkout's shell against the VM's generated config. Inside a Temple session, stop the running shell first.
shell:
    for f in themes backgrounds keybinds commands shell; do nix eval --raw "path:.#nixosConfigurations.vm.config.environment.etc.\"temple/$f.json\".text" > .tmp/$f.json || exit 1; done; TEMPLE_THEMES=.tmp/themes.json TEMPLE_BACKGROUNDS=.tmp/backgrounds.json TEMPLE_KEYBINDS=.tmp/keybinds.json TEMPLE_COMMANDS=.tmp/commands.json TEMPLE_SHELL_CONFIG=.tmp/shell.json qs -p shell

# Evaluate every flake output
check:
    nix flake check path:.

fmt:
    nix fmt
