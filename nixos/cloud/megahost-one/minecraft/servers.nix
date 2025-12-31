{
  inputs,
  lib,
  ...
}:
let
  whitelist = {
    # mojang
    Underslunky = "fe8d63f2-96c7-45a0-9fc3-aa454d5d9faa"; # A.
  };
  operators = {
    # drasl
    gothgirl = "137bb49c-9bf5-4479-9003-19fedacd7357"; # J.
    DukeRibbitIV = "709f1f59-2f07-4467-bcee-121e3f7755fc"; # B.

    # mojang
    StarchyPie = "458c712e-41cf-4b0a-9002-a112776661c9"; # F.
  };
  hostAddress4 = "10.0.0.1"; # /24
  containerAddress4 = "10.0.0.2";

  natBridgeName = "br-nat";

  felixPort = 25565;
in
{
  containers.minecraft-servers = {
    autoStart = true;
    privateNetwork = true;

    hostBridge = natBridgeName;
    localAddress = containerAddress4;

    forwardPorts = [
      { hostPort = felixPort; }
    ];

    bindMounts = {
      "/srv/minecraft" = {
        hostPath = "/srv/minecraft";
        isReadOnly = false;
      };
    };

    config =
      { pkgs, ... }:
      {
        imports = [
          inputs.nix-minecraft.nixosModules.minecraft-servers
        ];

        system.stateVersion = "25.11";

        nixpkgs.overlays = [ inputs.nix-minecraft.overlay ];

        networking.firewall.allowedTCPPorts = [ felixPort ];
        networking = {
          defaultGateway = {
            address = hostAddress4;
            interface = "eth0";
          };

          # use public DNS because I can't figure out how to get the host's DNS working right now.
          # https://developers.google.com/speed/public-dns/docs/using
          nameservers = [
            "8.8.8.8"
            "8.8.4.4"
          ];

          # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
          useHostResolvConf = lib.mkForce false;
        };

        services.minecraft-servers = {
          enable = true;
          eula = true;

          # we'll open the firewall ourselves, so that rcon stays firewalled.
          openFirewall = false;

          servers.felix = {
            enable = true;
            # max heap size 4G, initial heap size 2G
            jvmOpts = lib.concatStringsSep " " [
              "-Xmx4G"
              "-Xms2G"
              "-Dminecraft.api.env=custom"
              "-Dminecraft.api.auth.host=https://drasl.diffeq.com/auth"
              "-Dminecraft.api.account.host=https://drasl.diffeq.com/account"
              "-Dminecraft.api.profiles.host=https://drasl.diffeq.com/account"
              "-Dminecraft.api.session.host=https://drasl.diffeq.com/session"
              "-Dminecraft.api.services.host=https://drasl.diffeq.com/services"
            ];

            # Specify the custom minecraft server package
            package = pkgs.paperServers.paper-1_21_11;

            serverProperties = {
              motd = "a cool MC server";
              online-mode = true;
              white-list = true;
              enforce-whitelist = true;

              hardcore = false;

              server-port = felixPort;
            };

            whitelist = whitelist;
            operators = operators;
          };
        };
      };
  };
}
