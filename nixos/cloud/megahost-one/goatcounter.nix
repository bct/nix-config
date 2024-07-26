{ config, pkgs, ... }:
let
  cfgContainerSecrets = config.megahost.container-secrets;
  cfgContainerNetwork = config.megahost.container-network.bridge0.containers;
in {
  containers.goatcounter = {
    autoStart = true;
    privateNetwork = true;

    # note that we're not taking pkgs here - it doesn't have access to our overlays.
    # instead we're using the outer pkgs.
    # TODO: what does this all mean?
    config = { config, ... }: {
      system.stateVersion = "24.05";

      networking.firewall.allowedTCPPorts = [ 4000 ];

      systemd.services.goatcounter = {
        wantedBy = ["multi-user.target"];
        after = ["network.target"];

        serviceConfig = {
          Type = "simple";
          DynamicUser = true;

          LoadCredential = [
            "password-goatcounter:${cfgContainerSecrets.goatcounter.passwordGoatcounter.containerPath}"
          ];

          ExecStart = let
            run-goatcounter = pkgs.writeScript "run-goatcounter" ''
              #!/bin/sh

              set -euo pipefail

              password=$(cat $CREDENTIALS_DIRECTORY/password-goatcounter | tr -d '\n')

              # if we don't pass -email-from then it tries to look up the current
              # username, which doesn't work due to the chroot etc. below
              ${pkgs.goatcounter}/bin/goatcounter serve \
                -listen *:4000 \
                -db "postgresql+host=${cfgContainerNetwork.postgres.address6} password=$password sslmode=disable" \
                -tls http \
                -email-from goatcounter@m.diffeq.com
            '';

          in "${run-goatcounter}";

          Restart = "always";

          RuntimeDirectory = "goatcounter";
          RootDirectory = "/run/goatcounter";
          ReadWritePaths = "";
          BindReadOnlyPaths = [
            "/bin"
            builtins.storeDir
          ];

          PrivateDevices = true;
          PrivateUsers = true;

          CapabilityBoundingSet = "";
          RestrictNamespaces = true;
        };
      };
    };
  };

  age.secrets = {
    password-goatcounter.file = ../../../secrets/db/password-goatcounter.age;
  };

  megahost.container-secrets.goatcounter = {
    passwordGoatcounter = {
      hostPath = config.age.secrets.password-goatcounter.path;
    };
  };

  services.caddy = {
    enable = true;

    virtualHosts."m.diffeq.com".extraConfig = ''
      reverse_proxy [${cfgContainerNetwork.goatcounter.address6}]:4000 {
        # 2.5.0 has "-tls proxy" which should make this unnecessary
        # https://github.com/arp242/goatcounter/issues/647#issuecomment-1345559928
        header_down Set-Cookie "^(.*HttpOnly;) (SameSite=None)$" "$1 Secure; $2"
      }
    '';
  };
}
