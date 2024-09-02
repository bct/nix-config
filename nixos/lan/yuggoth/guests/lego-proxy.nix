{ self, config, pkgs, ... }:

let
  clients = [
    {
      domain = "spectator.domus.diffeq.com";
      pubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFk2zCBoSRaNUJfUhFNGLI1r+H5EVtWNukvTG6Lq0z+J spectator:lego-proxy-spectator";
    }
    {
      domain = "stereo.domus.diffeq.com";
      pubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGps5WovLRtcOWuBupjj2CC2YxVtQsHjHa4UN686eU3Q stereo:lego-proxy-spectator";
    }
  ];
in {
  # TODO: assert format of authorized keys (no newlines)

  imports = [
    "${self}/nixos/common/agenix-rekey.nix"
  ];

  system.stateVersion = "24.05";

  microvm = {
    vcpu = 1;
    mem = 256;
  };

  users.users.lego-proxy = let
    acme-zoneedit = pkgs.writeShellApplication {
      name = "acme-zoneedit";
      runtimeInputs = [ pkgs.curl ];
      text = builtins.readFile ../../../modules/acme-zoneedit/acme-zoneedit.sh;
    };
    mkCommand = authorizedDomain:
      pkgs.writeShellScript "lego-proxy-${authorizedDomain}" ''
        IFS=" "
        read action fqdn record <<<$SSH_ORIGINAL_COMMAND

        authorized_fqdn="_acme-challenge.${authorizedDomain}."

        if [ "$fqdn" != "$authorized_fqdn" ]; then
          echo "refusing to proxy request for $fqdn ($authorized_fqdn is authorized)"
          exit 1
        fi

        echo "lego-proxy: $action $fqdn"

        # source credentials to pass through to the script
        set -a
        source ${config.age.secrets.zoneedit.path}

        ${acme-zoneedit}/bin/acme-zoneedit "$action" "$fqdn" "$record"
      '';
  in {
    isSystemUser = true;
    group = "lego-proxy";

    # system users default to nologin.
    # sshd won't let us execute commands without a shell.
    useDefaultShell = true;

    openssh.authorizedKeys.keys = builtins.map ({ domain, pubKey }:
      "restrict,command=\"${mkCommand domain}\" ${pubKey}"
    ) clients;
  };
  users.groups.lego-proxy = {};

  age.rekey.hostPubkey = builtins.readFile ../../../../secrets/ssh/host-lego-proxy.pub;

  age.secrets = {
    zoneedit = {
      rekeyFile = ./lego-proxy/secrets/zoneedit.age;
      owner = "lego-proxy";
      group = "lego-proxy";
    };
  };
}
