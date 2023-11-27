{ lib, pkgs, config, ... }:

let
  cfg = config.services.acme-zoneedit;

  # bake the path to curl into our shell script
  acme-zoneedit-sh = pkgs.writeShellApplication {
    name = "acme-zoneedit.sh";
    runtimeInputs = [ pkgs.curl ];

    text = builtins.readFile ./acme-zoneedit.sh;
  };
in {
  options.services.acme-zoneedit = {
    enable = lib.mkEnableOption "acme-zoneedit";

    hostnames = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = lib.mdDoc "Hostnames to request certificates for.";
    };

    credentialsFile = lib.mkOption {
      type = lib.types.path;
      description = lib.mdDoc "Path to a file containing ZoneEdit credentials (ZONEEDIT_ID and ZONEEDIT_TOKEN).";
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
    security.acme.acceptTerms = true;

    security.acme.certs = builtins.listToAttrs (map (hostname: {
      name = hostname;
      value = {
        email = cfg.email;
        group = cfg.group;

        # set DNS TXT records by exec-ing acme-zoneedit.sh
        # (configured below)
        dnsProvider = "exec";
        credentialsFile = cfg.credentialsFile;

        # the nameserver internal to the network thinks it owns domus.diffeq.com.
        # use an external nameserver that will query the real world instead.
        dnsResolver = "8.8.8.8";
      };
    }) cfg.hostnames);

    # configure the "exec" DNS provider
    systemd.services = builtins.listToAttrs (map (hostname: {
      name = "acme-${hostname}";
      value = {
        environment = {
          EXEC_PATH = "${acme-zoneedit-sh}/bin/acme-zoneedit.sh";
          EXEC_PROPAGATION_TIMEOUT = "600";
        };
      };
    }) cfg.hostnames);

    # ns19.zoneedit.com doesn't respond on IPv6. if this host prefers IPv6
    # addresses then lego will complain that it wasn't able to get a response
    # from the authoritative nameserver.
    # as a hack we set it up to prefer IPv4 addresses.
    environment.etc."gai.conf".text = ''
       label  ::1/128       0
       label  ::/0          1
       label  2002::/16     2
       label ::/96          3
       label ::ffff:0:0/96  4

       precedence  ::1/128       50
       precedence  ::/0          40
       precedence  2002::/16     30
       precedence ::/96          20

       # prefer IPv4 addresses when both are available
       # (because zoneedit's DNS servers don't work properly over IPv6, which
       # breaks ACME)
       precedence ::ffff:0:0/96  100
    '';
  };
}
