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
    hostname = lib.mkOption {
      type = lib.types.str;
    };
    credentialsFile = lib.mkOption {
      type = lib.types.path;
    };
    email = lib.mkOption {
      type = lib.types.str;
    };
  };

  config = lib.mkIf cfg.enable {
    security.acme.acceptTerms = true;
    security.acme.certs.${cfg.hostname} = {
      email = cfg.email;

      # set DNS TXT records by exec-ing acme-zoneedit.sh
      # (configured below)
      dnsProvider = "exec";
      credentialsFile = cfg.credentialsFile;

      # the nameserver internal to the network thinks it owns domus.diffeq.com.
      # use an external nameserver that will query the real world instead.
      dnsResolver = "8.8.8.8";
    };

    # configure the "exec" DNS provider
    systemd.services."acme-${cfg.hostname}".environment = {
      EXEC_PATH = "${acme-zoneedit-sh}/bin/acme-zoneedit.sh";
      EXEC_PROPAGATION_TIMEOUT = "600";
    };

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
