args@{ self, inputs, config, ... }: {
  imports = [
    inputs.agenix.nixosModules.default

    "${self}/nixos/common/nix.nix"
    "${self}/nixos/common/headless.nix"

    "${self}/nixos/hardware/vultr"
  ];

  networking.hostName = "viator";

  time.timeZone = "Etc/UTC";

  #networking.firewall.allowedTCPPorts = [ 80 443 ];

  system.stateVersion = "23.05";
}
