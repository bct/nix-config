{ self, inputs, pkgs, ... }: {
  imports = [
    inputs.agenix.nixosModules.default

    "${self}/nixos/common/nix.nix"
    "${self}/nixos/common/headless.nix"

    "${self}/nixos/hardware/vultr"

    ./coredns-wgsd.nix
    ./wireguard.nix
  ];

  networking.hostName = "viator";

  time.timeZone = "Etc/UTC";

  system.stateVersion = "23.05";

  systemd.services.imap-jump-socat = {
    description = "Forwards IMAP via socat";

    after = ["network.target"];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      ExecStart = "${pkgs.socat}/bin/socat TCP-LISTEN:993,fork TCP:mail.domus.diffeq.com:993";
      Restart = "always";
    };
  };
}
