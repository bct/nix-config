# see yuggoth/nixvirt.nix for memory & CPU settings.
{ self, ... }:
{
  imports = [
    "${self}/nixos/vms/common/qemu-vm.nix"
    "${self}/nixos/common/agenix-rekey.nix"

    "${self}/nixos/common/nix.nix"
    "${self}/nixos/common/headless.nix"
    "${self}/nixos/common/node-exporter.nix"

    ./booklore.nix
    ./borgmatic.nix
    ./homepage.nix
    ./karakeep.nix
    ./tandoor.nix
    ./uptime-kuma.nix
    ./vikunja.nix

    "${self}/nixos/modules/lego-proxy-client"
  ];

  time.timeZone = "Etc/UTC";

  networking.hostName = "medley";
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMzt2gr8msbC0K/l5aoXLMWVTbAqgkRLR7SS3i6iLdQT";

  services.lego-proxy-client = {
    enable = true;
    domains = [
      "booklore"
      "bookmarks"
      "homepage"
      "recipes"
      "tasks"
      "uptime"
    ];
    group = "caddy";
  };

  system.stateVersion = "25.05";
}
