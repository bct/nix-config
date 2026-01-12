# see mi-go/nixvirt.nix for memory & CPU settings.
{ self, ... }:
{
  imports = [
    "${self}/nixos/vms/common/qemu-vm.nix"
    "${self}/nixos/common/agenix-rekey.nix"

    "${self}/nixos/common/nix.nix"
    "${self}/nixos/common/headless.nix"
    "${self}/nixos/common/node-exporter.nix"

    "${self}/nixos/modules/lego-proxy-client"

    ./accounts.nix
    ./flood.nix
    ./rtorrent.nix
  ];

  time.timeZone = "Etc/UTC";

  networking.hostName = "ranger";

  age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJTNt/y26ZktCI1KNHV0eWhpP8uiDBoNh5sy0lxPLewj";

  services.lego-proxy-client = {
    enable = true;
    domains = [
      "flood"
      "radarr"
      "sonarr"
    ];
    group = "caddy";
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  # TODO: centralize this
  fileSystems."/mnt/video" = {
    device = "/mnt/video";
    fsType = "virtiofs";
  };

  fileSystems."/bulk/downloads/pth" = {
    device = "/bulk/downloads/pth";
    fsType = "virtiofs";
  };

  fileSystems."/bulk/downloads/ggn" = {
    device = "/bulk/downloads/ggn";
    fsType = "virtiofs";
  };

  system.stateVersion = "25.11";
}
