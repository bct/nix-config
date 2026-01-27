{
  config,
  lib,
  self,
  ...
}:
{
  system.stateVersion = "25.11";

  imports = [
    "${self}/nixos/modules/lego-proxy-client"
  ];

  microvm = {
    vcpu = 1;
    mem = 512;

    volumes = [
      {
        image = "var.img";
        mountPoint = "/var";
        size = 1024;
      }
    ];

    shares = [
      {
        tag = "video";
        source = "/mnt/bulk/srv/syncthing";
        mountPoint = "/srv/syncthing";
        proto = "virtiofs";
      }
    ];
  };

  services.syncthing = {
    enable = true;
    openDefaultPorts = true;
    dataDir = "/srv/syncthing";
    configDir = "/var/lib/syncthing";
    # https://docs.syncthing.net/users/config.html
    settings = {
      gui = {
        authMode = "ldap";
      };
      # https://github.com/lldap/lldap/blob/main/example_configs/syncthing.md
      ldap = {
        address = "${config.diffeq.hostNames.ldap}:636";
        bindDN = "cn=%s,ou=people,dc=diffeq,dc=com";
        transport = "tls";
        searchBaseDN = "ou=people,dc=diffeq,dc=com";
        searchFilter = "(&(uid=%s)(memberof=cn=infra-owners,ou=groups,dc=diffeq,dc=com))";
      };
    };
    guiAddress = "127.0.0.1:8384";
    key = config.age.secrets.syncthing-key.path;
    cert = toString (builtins.path { path = ./secrets/syncthing-cert.pem; });

    # we'll manage this in the GUI.
    overrideFolders = false;
    overrideDevices = false;
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  # TODO: synchronize with host
  ids.uids.syncthing = lib.mkForce 983;
  ids.gids.syncthing = lib.mkForce 983;

  age.secrets = {
    syncthing-key.rekeyFile = ./secrets/syncthing-key.age;
  };

  services.caddy = {
    enable = true;
    virtualHosts."syncthing.domus.diffeq.com" = {
      useACMEHost = "syncthing.domus.diffeq.com";
      extraConfig = ''
        reverse_proxy localhost:8384 {
          header_up Host {upstream_hostport}
        }
      '';
    };
  };

  services.lego-proxy-client = {
    enable = true;
    domains = [ "syncthing" ];
    group = "caddy";
  };
}
