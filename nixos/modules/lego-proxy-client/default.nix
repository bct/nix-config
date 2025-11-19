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

  dnsResolver = "ns5.zoneedit.com";
  email = "s+acme@diffeq.com";

  clients = import ./clients.nix;
in {
  options.services.lego-proxy-client = with lib; {
    enable = mkEnableOption "lego-proxy-client";

    # TODO: proxy username, proxy host, proxy known host

    domains = mkOption {
      type = types.listOf types.str;
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "acme";
      description = lib.mdDoc "Group running the ACME client.";
    };
  };

  config = lib.mkIf cfg.enable {
    age.secrets = builtins.listToAttrs (builtins.map (domain:
      {
        name = "lego-proxy-${domain}";
        value = {
          generator.script = "ssh-ed25519-pubkey";
          rekeyFile = config.diffeq.secretsPath + /lego-proxy/${domain}.age;
          owner = "acme";
          group = "acme";
        };
      }
    ) cfg.domains);

    # TODO: readFile
    programs.ssh.knownHosts = {
      "lego-proxy.domus.diffeq.com".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMA5YAhyRoYYUPJOXWrFCxh6loBKK1fWuiFU3NgVj9iU root@lego-proxy";
    };

    security.acme.acceptTerms = true;

    security.acme.certs = builtins.listToAttrs (map (domain: let
      identity = config.age.secrets."lego-proxy-${domain}".path;
    in {
      name = clients.${domain}.domain;
      value = {
        email = email;
        group = cfg.group;

        # set DNS TXT records by exec-ing acme-zoneedit.sh
        # (configured below)
        dnsProvider = "exec";

        dnsResolver = dnsResolver;

        environmentFile = pkgs.writeText "" ''
          EXEC_PATH=${lego-proxy-client}/bin/lego-proxy-client
          EXEC_PROPAGATION_TIMEOUT=180
          SSH_IDENTITY=${identity}
        '';
      };
    }) cfg.domains);
  };
}
