{
  inputs,
  lib,
  config,
  ...
}:
let
  cfgContainerNetwork = config.megahost.container-network.bridge0.containers;
  draslPort = 27585;
  hostAddress4 = "10.0.0.1";
  containerAddress4 = "10.0.0.6/24";
in
{
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
  };

  # TODO: use ipv6 forwarding instead of NAT.
  # mojang addresses are accessible via ipv6.
  networking.nat = {
    enable = true;
    externalInterface = "ens3";
    internalInterfaces = [ "br0" ];
  };

  networking.interfaces.br0 = {
    ipv4.addresses = [
      {
        address = hostAddress4;
        prefixLength = 24;
      }
    ];
  };

  containers.drasl = {
    autoStart = true;
    privateNetwork = true;

    hostAddress = hostAddress4;
    localAddress = containerAddress4;

    config =
      { ... }:
      {
        imports = [ inputs.drasl.nixosModules.drasl ];

        system.stateVersion = "25.11";

        networking.firewall.allowedTCPPorts = [ draslPort ];

        services.resolved.enable = true;
        networking = {
          useDHCP = false;
          defaultGateway = hostAddress4;

          # Use systemd-resolved inside the container
          # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
          useHostResolvConf = lib.mkForce false;

          # https://developers.google.com/speed/public-dns/docs/using
          nameservers = [
            "8.8.8.8"
            "8.8.4.4"
            # "2001:4860:4860::8888"
            # "2001:4860:4860::8844"
          ];
        };

        # See https://github.com/unmojang/drasl/blob/master/doc/recipes.md
        # Especially "Proxy multiple authentication servers" and "Configuration for common fallback servers: Mojang"
        services.drasl = {
          enable = true;
          settings = {
            Domain = "drasl.diffeq.com";
            BaseURL = "https://drasl.diffeq.com";
            ListenAddress = "0.0.0.0:${toString draslPort}";
            DefaultAdmins = [ ];

            RegistrationNewPlayer = {
              Allow = false;
              # Allow = true;
              # RequireInvite = false;
            };

            CreateNewPlayer = {
              AllowChoosingUUID = true;
            };

            FallbackAPIServers = [
              {
                Nickname = "Mojang";
                SessionURL = "https://sessionserver.mojang.com";
                AccountURL = "https://api.mojang.com";
                ServicesURL = "https://api.minecraftservices.com";
                SkinDomains = [ "textures.minecraft.net" ];
                CacheTTLSeconds = 60;
              }
            ];
          };
        };
      };
  };

  services.caddy = {
    enable = true;
    virtualHosts."drasl.diffeq.com".extraConfig = ''
      reverse_proxy [${cfgContainerNetwork.drasl.address6}]:${toString draslPort}
    '';
  };
}
