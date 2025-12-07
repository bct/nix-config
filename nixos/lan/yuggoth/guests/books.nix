{
  self,
  config,
  pkgs,
  ...
}:
{
  imports = [
    "${self}/nixos/common/agenix-rekey.nix"
    "${self}/nixos/modules/lego-proxy-client"
  ];

  system.stateVersion = "25.05";

  microvm = {
    vcpu = 1;
    mem = 1024;

    volumes = [
      {
        image = "/dev/mapper/ssdpool-books--var";
        mountPoint = "/var";
        autoCreate = false;
      }
    ];
  };

  services.lego-proxy-client = {
    enable = true;
    domains = [ "books" ];
    group = "caddy";
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  services.calibre-web = {
    enable = true;
    openFirewall = false;
    options = {
      enableBookConversion = true;
      enableKepubify = true;
      enableBookUploading = true;
    };

    # https://github.com/NixOS/nixpkgs/issues/405974
    package = pkgs.calibre-web.overridePythonAttrs (old: {
      # gevent may allow larger uploads
      dependencies =
        old.dependencies
        ++ old.optional-dependencies.kobo
        ++ old.optional-dependencies.metadata
        ++ [ pkgs.python3Packages.gevent ];
    });
  };

  services.caddy = {
    enable = true;
    virtualHosts."books.domus.diffeq.com" = {
      useACMEHost = "books.domus.diffeq.com";

      # https://github.com/janeczku/calibre-web/issues/2960
      extraConfig = ''
        reverse_proxy localhost:${toString config.services.calibre-web.listen.port} {
           header_up X-Scheme https
        }

        request_body {
          max_size 512MB
        }
      '';
    };
  };
}
