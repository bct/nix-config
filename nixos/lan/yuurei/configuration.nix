{ self, ... }: {
  imports = [
    "${self}/nixos/common/nix.nix"
    "${self}/nixos/common/headless.nix"

    ./hardware-configuration.nix
  ];

  networking.hostName = "yuurei";

  time.timeZone = "Etc/UTC";

  system.stateVersion = "23.05";
}
