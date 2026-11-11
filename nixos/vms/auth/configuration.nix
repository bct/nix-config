# see yuggoth/nixvirt.nix for memory & CPU settings.
{ self, ... }:
{
  imports = [
    "${self}/nixos/vms/common/qemu-vm.nix"
    "${self}/nixos/modules/guest-network/client.nix"
    "${self}/nixos/common/agenix-rekey.nix"

    "${self}/nixos/common/nix.nix"
    "${self}/nixos/common/headless.nix"
    "${self}/nixos/common/node-exporter.nix"

    ./ldap.nix
    ./dex.nix
    ./tinyauth.nix

    "${self}/nixos/modules/lego-proxy-client"
  ];

  time.timeZone = "Etc/UTC";

  networking.hostName = "auth";

  # routed guest of yuggoth; address etc. come from yuggoth/nixvirt.nix.
  diffeq.guestNetworkClient = self.nixosConfigurations.yuggoth.config.diffeq.guestNetwork.guests.auth;

  age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID8MCMkvatrPkoxKMQA/GgjpNJaD1IoMQuOu1XiJVac2";

  system.stateVersion = "25.11";

  services.lego-proxy-client = {
    enable = true;
    domains = [
      "oidc" # dex
      "ldap" # lldap
      "auth" # tinyauth
    ];
    group = "caddy";
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
