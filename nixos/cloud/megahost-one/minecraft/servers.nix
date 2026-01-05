{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  whitelist = {
    # mojang
    Underslunky = "fe8d63f2-96c7-45a0-9fc3-aa454d5d9faa"; # A.
  };
  operators = {
    # drasl
    GothGirl = "137bb49c-9bf5-4479-9003-19fedacd7357"; # J.
    DukeRibbitIV = "709f1f59-2f07-4467-bcee-121e3f7755fc"; # B.

    # mojang/drasl
    StarchyPie = "458c712e-41cf-4b0a-9002-a112776661c9"; # F.
  };

  draslJvmOpts = [
    "-Dminecraft.api.env=custom"
    "-Dminecraft.api.auth.host=https://drasl.diffeq.com/auth"
    "-Dminecraft.api.account.host=https://drasl.diffeq.com/account"
    "-Dminecraft.api.profiles.host=https://drasl.diffeq.com/account"
    "-Dminecraft.api.session.host=https://drasl.diffeq.com/session"
    "-Dminecraft.api.services.host=https://drasl.diffeq.com/services"
  ];

  hostAddress4 = "10.0.0.1"; # /24
  containerAddress4 = "10.0.0.2";

  natBridgeName = "br-nat";

  coolWorldPort = 25565;
  swemPort = 25566;

  # https://github.com/Infinidoge/nix-minecraft/issues/122#issuecomment-2916427568
  forge-1_20_1 =
    let
      version = "1.20.1-47.3.0";
      installer = pkgs.fetchurl {
        pname = "forge-installer";
        inherit version;
        url = "https://maven.minecraftforge.net/net/minecraftforge/forge/${version}/forge-${version}-installer.jar";
        hash = "sha256-YBirzpXMBYdo42WGX9fPO9MbXFUyMdr4hdw4X81th1o=";
      };
      java = "${pkgs.jdk}/bin/java";
    in
    pkgs.writeShellScriptBin "server" ''
      forge_path="libraries/net/minecraftforge/forge/${version}"
      if ! [ -d "$forge_path" ]; then
        ${java} -jar ${installer} --installServer
      fi
      exec ${java} $@ @"$forge_path"/unix_args.txt nogui
    '';
in
{
  containers.minecraft-servers = {
    autoStart = true;
    privateNetwork = true;

    hostBridge = natBridgeName;
    localAddress = containerAddress4;

    forwardPorts = [
      { hostPort = coolWorldPort; }
      { hostPort = swemPort; }
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

        networking.firewall.allowedTCPPorts = [
          coolWorldPort
          swemPort
        ];
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

          servers.cool-world = {
            enable = true;
            # max heap size 4G, initial heap size 2G
            jvmOpts = lib.concatStringsSep " " (
              [
                "-Xmx4G"
                "-Xms2G"
              ]
              ++ draslJvmOpts
            );

            # Specify the custom minecraft server package
            package = pkgs.paperServers.paper-1_21_11;

            serverProperties = {
              motd = "a cool MC server";
              online-mode = true;
              white-list = true;
              enforce-whitelist = true;

              hardcore = false;

              server-port = coolWorldPort;
            };

            whitelist = whitelist;
            operators = operators;
          };

          servers.swem = {
            enable = true;
            # max heap size 4G, initial heap size 2G
            jvmOpts = lib.concatStringsSep " " (
              [
                "-Xmx4G"
                "-Xms2G"
              ]
              ++ draslJvmOpts
            );

            # Specify the custom minecraft server package
            package = forge-1_20_1;

            serverProperties = {
              motd = "horsies!";
              online-mode = true;
              white-list = true;
              enforce-whitelist = true;

              hardcore = false;

              server-port = swemPort;
            };

            whitelist = whitelist;
            operators = operators;
          };
        };
      };
  };
}
