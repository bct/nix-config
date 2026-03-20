{ inputs, ... }:
{
  system.stateVersion = "25.11";

  imports = [
    inputs.stump-nix.nixosModules.stump
  ];

  networking.firewall.allowedTCPPorts = [ 10801 ];

  services.stump = {
    enable = true;
    environment = {
      STUMP_PORT = "10801";
    };
  };
}
