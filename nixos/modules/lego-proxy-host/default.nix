{ lib, pkgs, config, ... }: let
  cfg = config.services.lego-proxy-host;

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

      ${cfg.execCommand} "$action" "$fqdn" "$record"
    '';
in {
  # TODO: assert format of authorized keys (no newlines)

  options.services.lego-proxy-host = with lib; {
    enable = mkEnableOption "lego-proxy-host";

    execCommand = mkOption {
      type = types.str;
    };

    clients = mkOption {
      type = types.listOf (types.submodule (
        {...}: {
          options = {
            domain = mkOption {
              type = types.str;
            };

            pubKey = mkOption {
              type = types.str;
            };
          };
        }
      ));
    };
  };

  config = lib.mkIf cfg.enable {
    services.openssh = {
      enable = true;
    };

    users.users.lego-proxy = {
      isSystemUser = true;
      group = "lego-proxy";

      # system users default to nologin.
      # sshd won't let us execute commands without a shell.
      useDefaultShell = true;

      openssh.authorizedKeys.keys = builtins.map ({ domain, pubKey }:
        "restrict,command=\"${mkCommand domain}\" ${pubKey}"
      ) cfg.clients;
    };
    users.groups.lego-proxy = {};
  };
}
