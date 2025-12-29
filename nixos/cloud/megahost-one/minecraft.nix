{ inputs, pkgs, ... }:
{
  imports = [
    inputs.nix-minecraft.nixosModules.minecraft-servers
  ];

  nixpkgs.overlays = [ inputs.nix-minecraft.overlay ];

  services.minecraft-servers = {
    enable = true;
    eula = true;

    # we'll open the firewall ourselves, so that rcon stays firewalled.
    openFirewall = false;

    servers.felix = {
      enable = true;
      # max heap size 4G, initial heap size 2G
      jvmOpts = "-Xmx4G -Xms2G";

      # Specify the custom minecraft server package
      package = pkgs.paperServers.paper-1_21_11;

      serverProperties = {
        motd = "a cool MC server";
        online-mode = false;
        white-list = true;
        enforce-whitelist = true;

        hardcore = false;
      };

      whitelist = {
        # Alec
        Underslunky = "59b6707e-dc42-3b37-94b9-efb133765fc3";
      };

      operators = {
        daddio = "0212f24d-c226-3a71-8e78-eafbe4ff6fdf";
        TheRizzlord = "63ad1f7c-d015-3726-934a-a33c8aa861c5";
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 25565 ];
}
