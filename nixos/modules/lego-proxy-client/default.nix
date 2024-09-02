{ lib, pkgs, config, ... }:

let
  cfg = config.services.lego-proxy-client;

  lego-proxy-client = pkgs.writeShellApplication {
    name = "lego-proxy-client";
    runtimeInputs = [ pkgs.openssh ];

    text = ''
      ssh -i "$SSH_IDENTITY" lego-proxy@lego-proxy.domus.diffeq.com "$@"
    '';
  };
in {
  options.services.lego-proxy-client = with lib; {
    enable = mkEnableOption "lego-proxy-client";

    # TODO: proxy username, proxy host, proxy known host

    dnsResolver = mkOption {
      type = types.str;
    };

    domains = mkOption {
      type = types.listOf (types.submodule (
        {...}: {
          options = {
            identity = mkOption {
              type = types.path;
            };

            domain = mkOption {
              type = types.str;
            };
          };
        }
      ));
    };

    email = lib.mkOption {
      type = lib.types.str;
      description = lib.mdDoc "Email address to use when requsting certificates";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "acme";
      description = lib.mdDoc "Group running the ACME client.";
    };
  };

  config = lib.mkIf cfg.enable {
    # TODO: readFile
    programs.ssh.knownHosts = {
      "lego-proxy.domus.diffeq.com".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMA5YAhyRoYYUPJOXWrFCxh6loBKK1fWuiFU3NgVj9iU root@lego-proxy";
    };

    security.acme.acceptTerms = true;

    security.acme.certs = builtins.listToAttrs (map ({ domain, identity }: {
      name = domain;
      value = {
        email = cfg.email;
        group = cfg.group;

        # set DNS TXT records by exec-ing acme-zoneedit.sh
        # (configured below)
        dnsProvider = "exec";

        dnsResolver = cfg.dnsResolver;

        environmentFile = pkgs.writeText "" ''
          EXEC_PATH=${lego-proxy-client}/bin/lego-proxy-client
          SSH_IDENTITY=${identity}
        '';
      };
    }) cfg.domains);
  };
}
