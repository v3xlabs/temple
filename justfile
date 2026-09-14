default:
    @just --list

# Build and boot the Temple VM (login: temple / temple, autologin into the Temple session)
vm:
    nix run path:.#vm

# Build the VM without booting it
build:
    nix build path:.#vm

# Run the shell on the host, against the checked-in dark theme
shell:
    nix eval --json path:.#themes.dark > .tmp/theme.json && nix eval --raw 'path:.#nixosConfigurations.vm.config.environment.etc."temple/backgrounds.json".text' > .tmp/backgrounds.json && nix eval --raw 'path:.#nixosConfigurations.vm.config.environment.etc."temple/keybinds.json".text' > .tmp/keybinds.json && TEMPLE_THEME=.tmp/theme.json TEMPLE_BACKGROUNDS=.tmp/backgrounds.json TEMPLE_KEYBINDS=.tmp/keybinds.json qs -p shell

# Evaluate every flake output
check:
    nix flake check path:.

fmt:
    nix fmt
