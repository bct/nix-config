{ self, inputs, pkgs, ... }: {
  imports = [
    inputs.agenix.nixosModules.default
    inputs.disko.nixosModules.disko

    "${self}/nixos/common/nix.nix"
    "${self}/nixos/common/headless.nix"

    "${self}/nixos/hardware/vultr"

    ./disk-config.nix
#    ./coredns-wgsd.nix
#    ./wireguard.nix
  ];

  # we'll configure these using disko.
  hardware.vultr.useSwapFile = false;
  hardware.vultr.setUpDisk = false;

  networking.hostName = "megahost-one";

  time.timeZone = "Etc/UTC";

  system.stateVersion = "24.05";
}
