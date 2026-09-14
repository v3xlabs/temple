{pkgs, ...}: {
  temple.enable = true;

  networking.hostName = "temple";
  time.timeZone = "Europe/Amsterdam";

  users.users.temple = {
    isNormalUser = true;
    password = "temple";
    extraGroups = ["wheel" "video" "input"];
  };
  security.sudo.wheelNeedsPassword = false;

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };
  services.displayManager.autoLogin = {
    enable = true;
    user = "temple";
  };
  services.displayManager.defaultSession = "temple";

  environment.systemPackages = [pkgs.kdePackages.qtwayland];

  virtualisation.vmVariant.virtualisation = {
    cores = 8;
    memorySize = 8192;
    diskSize = 16384;
    qemu.options = [
      "-vga none"
      "-device virtio-vga,xres=1920,yres=1080"
      "-display gtk,show-cursor=on"
    ];
    # virtiofs shares the host Nix store, and its vhost-user device needs guest
    # RAM in shared memory. qemu-vm.nix only enables this for NixOS tests.
    qemu.enableSharedMemory = true;
  };

  # nixosConfigurations.vm is also evaluated as a plain toplevel by
  # `nix flake check`, and that evaluation needs a root fs and a bootloader.
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
  boot.loader.grub.device = "nodev";

  system.stateVersion = "26.05";
}
