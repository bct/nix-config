# see yuggoth/nixvirt.nix for memory & CPU settings.
{ self, inputs, ... }: let
  nixpkgs = inputs.nixpkgs;
in {
  imports = [
    "${nixpkgs}/nixos/modules/profiles/qemu-guest.nix"

    "${self}/nixos/common/agenix-rekey.nix"

    "${self}/nixos/common/nix.nix"
    "${self}/nixos/common/headless.nix"
    "${self}/nixos/common/node-exporter.nix"

    ./hardware-configuration.nix

    ./homepage.nix
    ./karakeep.nix
    ./tandoor.nix

    "${self}/nixos/modules/lego-proxy-client"
  ];

  # https://github.com/nix-community/nixos-generators/blob/master/formats/qcow.nix
  boot.growPartition = true;
  boot.loader.grub.device = "/dev/vda";
  boot.loader.timeout = 0;

  time.timeZone = "Etc/UTC";

  networking.hostName = "medley";
  networking.firewall.allowedTCPPorts = [ 80 443 ];

  age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMzt2gr8msbC0K/l5aoXLMWVTbAqgkRLR7SS3i6iLdQT";

  services.lego-proxy-client = {
    enable = true;
    domains = [ "bookmarks" "homepage" "recipes" ];
    group = "caddy";
  };

  system.stateVersion = "25.05";
}
