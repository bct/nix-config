{ self, inputs, config, pkgs, ... }: {
  imports = [
    inputs.agenix.nixosModules.default

    "${self}/nixos/common/nix.nix"
    "${self}/nixos/common/headless.nix"

    "${self}/nixos/hardware/vultr"
  ];

  networking.hostName = "notes";

  time.timeZone = "Etc/UTC";

  system.stateVersion = "23.05";

  nixpkgs = {
    overlays = [
      # workaround: add pg_dump, pg_restore, psql to borgmatic's PATH
      # this is temporary until we've upgraded past 1.7.13:
      # https://projects.torsion.org/borgmatic-collective/borgmatic/issues/678
      (_final: prev: {
        borgmatic = prev.borgmatic.overrideAttrs (old: {
          propagatedBuildInputs = old.propagatedBuildInputs ++ [config.services.postgresql.package];
        });
      })
    ];
  };

  systemd.network = {
    netdevs."20-wg0" = {
      netdevConfig = {
        Kind = "wireguard";
        Name = "wg0";
      };
      wireguardConfig = {
        ListenPort = 51820;
        PrivateKeyFile = config.age.secrets.notes-wireguard-key.path;
      };
      wireguardPeers = [{
        wireguardPeerConfig = {
          # conductum
          PublicKey = "fBOs8h31Jce8FH0eeeKWLvtXNSD7a6PkQoYiJtoOxUo=";
          AllowedIPs = [ "192.168.9.1/32" "192.168.0.0/16" ];
        };
      }];
    };

    networks."20-wg0" = {
      matchConfig.Name = "wg0";
      address = ["192.168.9.3/16"];

      # use the home router for DNS, so that we resolve borg.domus.diffeq.com to
      # its VPN IP.
      dns = ["192.168.9.1"];
      domains = ["~domus.diffeq.com"];
    };
  };

  environment.systemPackages = with pkgs; [
    # for the "vikunja" cli tool
    vikunja-api

    goatcounter
  ];

  networking.firewall.allowedTCPPorts = [ 80 443 ];
  networking.firewall.allowedUDPPorts = [ 51820 ];

  services.caddy = {
    enable = true;

    virtualHosts."tasks.diffeq.com".extraConfig = ''
      root * ${pkgs.vikunja-frontend}
      encode gzip
      file_server

      reverse_proxy /api/* localhost:3456
      reverse_proxy /.well-known/* localhost:3456
      reverse_proxy /dav/* localhost:3456
    '';

    virtualHosts."notes.diffeq.com".extraConfig = ''
      reverse_proxy localhost:3000
    '';

    virtualHosts."m.diffeq.com".extraConfig = ''
      reverse_proxy localhost:4000 {
        # https://github.com/arp242/goatcounter/issues/647#issuecomment-1345559928
        header_down Set-Cookie "^(.*HttpOnly;) (SameSite=None)$" "$1 Secure; $2"
      }
    '';

    virtualHosts."diffeq.com".extraConfig = ''
      root * /srv/diffeq.com

      # I don't have any content at /, so just redirect to my about page
      redir / /bct temporary

      # https://caddy.community/t/how-to-serve-html-files-without-showing-the-html-extension/16766/3
      try_files {path}.html
      encode gzip
      file_server
    '';
  };

  services.postgresql = {
    enable = true;

    # allow root to log in as "postgres" without a password.
    # this seems like the easiest way for root to dump the database during backups.
    authentication = ''
      # TYPE  DATABASE        USER            ADDRESS                 METHOD
      local   all             postgres                                peer map=root
    '';
    identMap = ''
      # MAPNAME       SYSTEM-USERNAME PG-USERNAME
      root            root            postgres
      root            postgres        postgres
    '';

    ensureDatabases = [ "vikunja" "wiki" "goatcounter" ];

    ensureUsers = [
      {
        name = "vikunja-api";
        ensurePermissions = {
          "DATABASE vikunja" = "ALL PRIVILEGES";
        };
      }

      {
        name = "wiki-js";
        ensurePermissions = {
          "DATABASE wiki" = "ALL PRIVILEGES";
        };
      }

      {
        name = "goatcounter";
        ensurePermissions = {
          "DATABASE goatcounter" = "ALL PRIVILEGES";
        };
      }
    ];
  };

  services.vikunja = {
    enable = true;
    frontendScheme = "https";
    frontendHostname = "tasks.diffeq.com";

    database = {
      type = "postgres";
      user = "vikunja-api";
      host = "/run/postgresql";
    };

    settings.service = {
      enableregistration = false;
    };
  };

  services.wiki-js = {
    enable = true;
    settings = {
      bindIp = "127.0.0.1";
      port = 3000;

      db = {
        user = "wiki-js";
        host = "/run/postgresql";
      };
    };
  };

  systemd.services.goatcounter = {
    wantedBy = ["multi-user.target"];
    after = ["network.target" "postgresql.service"];

    serviceConfig = {
      Type = "simple";
      DynamicUser = true;
      # if we don't pass -email-from then it tries to look up the current
      # username, which doesn't work due to the chroot etc. below
      ExecStart = "${pkgs.goatcounter}/bin/goatcounter serve -listen 127.0.0.1:4000 -db 'postgresql+host=/run/postgresql' -tls http -email-from goatcounter@m.diffeq.com";
      Restart = "always";

      RuntimeDirectory = "goatcounter";
      RootDirectory = "/run/goatcounter";
      ReadWritePaths = "";
      BindReadOnlyPaths = [
        "/run/postgresql/"
        builtins.storeDir
      ];

      PrivateDevices = true;
      PrivateUsers = true;

      CapabilityBoundingSet = "";
      RestrictNamespaces = true;
    };
  };

  services.borgmatic = {
    enable = true;
    settings = {
      location.source_directories = [
        "/var/lib/vikunja"
        "/var/lib/wiki-js"
      ];

      location.repositories = [
        "ssh://borg@borg.domus.diffeq.com/srv/borg/notes.diffeq.com/"
      ];

      hooks.postgresql_databases = [
        {
          name = "all";
          username = "postgres";

          # dump each database to a separate file.
          format = "custom";

          # TODO: enable these once we no longer need the workaround overlay.
          #pg_dump_command = "${config.services.postgresql.package}/bin/pg_dump";
          #pg_restore_command = "${config.services.postgresql.package}/bin/pg_restore";
          #psql_command = "${config.services.postgresql.package}/bin/psql";
        }
      ];

      storage.ssh_command = "ssh -i ${config.age.secrets.notes-borg-ssh-key.path}";

      retention = {
        keep_daily = 7;
        keep_weekly = 4;
        keep_monthly = 6;
        keep_yearly = 1;
      };

      hooks.ntfy = {
        topic = "doog4maechoh";
        fail = {
          title = "[notes] borgmatic failed";
          message = "Your backup has failed.";
          priority = "default";
          tags = "sweat,borgmatic";
          states = ["fail"];
        };
      };
    };
  };

  age.secrets = {
    notes-wireguard-key = {
      file = ../../../secrets/notes-wireguard-key.age;
      owner = "systemd-network";
      group = "systemd-network";
      mode = "600";
    };

    notes-borg-ssh-key = {
      file = ../../../secrets/notes-borg-ssh-key.age;
      owner = "root";
      group = "root";
      mode = "600";
    };
  };
}
