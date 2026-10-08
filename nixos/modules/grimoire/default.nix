{ lib, pkgs, config, ... }:

let
  cfg = config.services.grimoire;
  pythonEnv = cfg.package.python;
in
{
  options.services.grimoire = {
    enable = lib.mkEnableOption "Grimoire, a self-hosted TTRPG library manager";

    package = lib.mkPackageOption pkgs "grimoire" { };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Address for the uvicorn server to bind to.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 9481;
      description = "Port for the uvicorn server to listen on.";
    };

    workers = lib.mkOption {
      type = lib.types.ints.positive;
      default = 2;
      description = "Number of uvicorn worker processes.";
    };

    libraryPath = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/grimoire/library";
      description = ''
        Directory of PDFs, maps, tokens, audio, and 3D models for Grimoire to
        index. Created and chowned to `user`/`group` on activation.
      '';
    };

    dataPath = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/grimoire/data";
      description = ''
        Directory for Grimoire's database, thumbnails, page cache, and other
        application state. Created and chowned to `user`/`group` on
        activation.
      '';
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "grimoire";
      description = "User to run grimoire as.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "grimoire";
      description = "Group to run grimoire as.";
    };

    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        A systemd `EnvironmentFile` for secrets such as `SECRET_KEY`,
        `VALKEY_URL` credentials, or OIDC client secrets. See
        <https://github.com/hunter-read/grimoire/blob/main/docs/configuration.md>.
        `SECRET_KEY` is optional: Grimoire generates and persists one under
        `dataPath` if unset, but that only works for a single replica.
      '';
    };

    environment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = {
        OPDS_ENABLED = "true";
        BASE_URL = "https://grimoire.example.com";
      };
      description = "Extra (non-secret) environment variables for Grimoire.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to open the firewall for `port`.";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users = lib.mkIf (cfg.user == "grimoire") {
      grimoire = {
        isSystemUser = true;
        group = cfg.group;
      };
    };

    users.groups = lib.mkIf (cfg.group == "grimoire") { grimoire = { }; };

    systemd.tmpfiles.rules = [
      "d '${cfg.libraryPath}' 0750 ${cfg.user} ${cfg.group} - -"
      "d '${cfg.dataPath}' 0750 ${cfg.user} ${cfg.group} - -"
    ];

    systemd.services.grimoire = {
      description = "Grimoire — self-hosted TTRPG library manager";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      environment = {
        LIBRARY_PATH = cfg.libraryPath;
        DATA_PATH = cfg.dataPath;
      } // cfg.environment;

      serviceConfig =
        {
          ExecStart = "${lib.getExe' pythonEnv "python"} -m uvicorn backend.main:app --host ${cfg.host} --port ${toString cfg.port} --workers ${toString cfg.workers}";
          WorkingDirectory = "${cfg.package}/share/grimoire";

          User = cfg.user;
          Group = cfg.group;
          Restart = "on-failure";
          RestartSec = 5;

          ProtectSystem = "strict";
          ProtectHome = true;
          PrivateTmp = true;
          NoNewPrivileges = true;
          ReadWritePaths = [
            cfg.libraryPath
            cfg.dataPath
          ];
        }
        // lib.optionalAttrs (cfg.environmentFile != null) {
          EnvironmentFile = cfg.environmentFile;
        };
    };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];
  };
}
