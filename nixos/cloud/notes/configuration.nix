args@{ self, inputs, config, ... }: {
  imports = [
    "${self}/nixos/common/nix.nix"
    "${self}/nixos/common/headless.nix"

    ./hardware-configuration.nix
  ];

  boot.loader.grub.device = "/dev/vda";

  networking.hostName = "notes";

  time.timeZone = "Etc/UTC";

  system.stateVersion = "23.05";
}
