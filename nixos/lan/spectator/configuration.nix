{ self, inputs, ... }: {
  imports = [
    inputs.agenix.nixosModules.default

    "${self}/nixos/common/nix.nix"
    "${self}/nixos/common/headless.nix"

    "${self}/nixos/hardware/raspberry-pi"

    ./home-assistant.nix
    ./rtlamr.nix

    ./hardware-configuration.nix
  ];

  networking.hostName = "spectator";
  networking.useNetworkd = true;

  systemd.network = {
    enable = true;

    networks."10-lan" = {
      matchConfig.Type = "ether";
      networkConfig.DHCP = "yes";
    };

    networks."10-wlan" = {
      matchConfig.Type = "wlan";
      linkConfig.Unmanaged = "yes";
    };
  };

  time.timeZone = "America/Edmonton";

  # Disable the firewall altogether.
  networking.firewall.enable = false;

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "22.11";
}
