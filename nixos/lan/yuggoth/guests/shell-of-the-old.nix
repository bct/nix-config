{ self, inputs, config, pkgs, ... }: {
  imports = [
    "${self}/nixos/common/agenix-rekey.nix"
    "${self}/nixos/modules/lego-proxy-client"
  ];

  system.stateVersion = "24.11";

  microvm = {
    vcpu = 1;
    mem = 4096;

    volumes = [
      {
        image = "/dev/mapper/ssdpool-shelloftheold--root";
        mountPoint = "/";
        autoCreate = false;
      }
    ];
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];

  age.secrets = {
    lego-proxy-shell-of-the-old = {
      generator.script = "ssh-ed25519-pubkey";
      rekeyFile = ../../../../secrets/lego-proxy/shell-of-the-old.age;
      owner = "acme";
      group = "acme";
    };
  };

  services.lego-proxy-client = {
    enable = true;
    domains = [
      { domain = "shell-of-the-old.domus.diffeq.com"; identity = config.age.secrets.lego-proxy-shell-of-the-old.path; }
    ];
    group = "caddy";
    dnsResolver = "ns5.zoneedit.com";
    email = "s+acme@diffeq.com";
  };

  services.caddy = {
    enable = true;
    virtualHosts."shell-of-the-old.domus.diffeq.com" = {
      useACMEHost = "shell-of-the-old.domus.diffeq.com";
      extraConfig = ''
        reverse_proxy localhost:8080
        header Referrer-Policy no-referrer
      '';
    };
  };
}
