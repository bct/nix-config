{
  lib,
  config,
  inputs,
  ...
}:

let
  cfg = config.services.lego-proxy-client;

  dnsResolver = "ns5.zoneedit.com";
  email = "s+acme@diffeq.com";

  clients = import ./clients.nix;

  proxyHostKey = builtins.readFile (config.diffeq.secretsPath + /ssh/host-lego-proxy.pub);
in
{
  imports = [ inputs.acme-dns-by-proxy.nixosModules.client ];

  options.services.lego-proxy-client = with lib; {
    enable = mkEnableOption "lego-proxy-client";

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
    age.secrets = builtins.listToAttrs (
      builtins.map (domain: {
        name = "lego-proxy-${domain}";
        value = {
          generator.script = "ssh-ed25519-pubkey";
          rekeyFile = config.diffeq.secretsPath + /lego-proxy/${domain}.age;
          owner = "acme";
          group = "acme";
        };
      }) cfg.domains
    );

    security.acme.acceptTerms = true;

    security.acme.certs = builtins.listToAttrs (
      map (
        domain:
        lib.nameValuePair clients.${domain}.domain {
          email = email;
          group = cfg.group;
          dnsResolver = dnsResolver;
        }
      ) cfg.domains
    );

    security.acme.dnsChallengeProxies = builtins.listToAttrs (
      map (
        domain:
        lib.nameValuePair clients.${domain}.domain {
          host = "lego-proxy.domus.diffeq.com";
          sshIdentity = config.age.secrets."lego-proxy-${domain}".path;
          hostKey = proxyHostKey;
        }
      ) cfg.domains
    );
  };
}
