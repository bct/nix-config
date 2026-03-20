{
  inputs,
  pkgs,
  lib,
  ...
}:
let
  whitelist = {
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

  berkPort = 25565;

  # https://github.com/Infinidoge/nix-minecraft/issues/122#issuecomment-2916427568
  forge-1_18_2 =
    let
      version = "1.18.2-40.3.0";
      installer = pkgs.fetchurl {
        pname = "forge-installer";
        inherit version;
        url = "https://maven.minecraftforge.net/net/minecraftforge/forge/${version}/forge-${version}-installer.jar";
        hash = "sha256-lDTCl5BQTc0RzpfLMN2IkbSxiEiYI1e8G1q/p5+5UQM=";
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
  microvm = {
    vcpu = 1;
    mem = 4608;

    volumes = [
      {
        image = "srv.img";
        mountPoint = "/srv";
        size = 2048;
      }
    ];
  };

  system.stateVersion = "25.11";

  imports = [
    inputs.nix-minecraft.nixosModules.minecraft-servers
  ];

  nixpkgs.overlays = [ inputs.nix-minecraft.overlay ];

  networking.firewall.allowedTCPPorts = [
    berkPort
  ];

  services.minecraft-servers = {
    enable = true;
    eula = true;

    # we'll open the firewall ourselves, so that rcon stays firewalled.
    openFirewall = false;

    servers.berk = {
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
      package = forge-1_18_2;

      serverProperties = {
        motd = "dragons!";
        online-mode = true;
        white-list = true;
        enforce-whitelist = true;

        hardcore = false;

        server-port = berkPort;
      };

      whitelist = whitelist;
      operators = operators;
    };
  };
}
