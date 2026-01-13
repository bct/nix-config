{
  self,
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    "${self}/nixos/modules/lego-proxy-client"
  ];

  system.stateVersion = "24.05";

  microvm = {
    vcpu = 2;
    mem = 2560;

    volumes = [
      {
        image = "var.img";
        mountPoint = "/var";
        size = 1024;
      }
    ];
  };

  services.lego-proxy-client = {
    enable = true;
    domains = [ "paperless" ];
    group = "caddy";
  };

  services.paperless = {
    enable = true;
    mediaDir = "/mnt/paperless/media";
    environmentFile = config.age.secrets.paperless-env.path;
    consumptionDirIsPublic = true;

    settings = {
      PAPERLESS_URL = "https://paperless.domus.diffeq.com";
      PAPERLESS_DBHOST = "db.domus.diffeq.com";

      PAPERLESS_APPS = "allauth.socialaccount.providers.openid_connect";
      PAPERLESS_SOCIALACCOUNT_PROVIDERS = builtins.toJSON {
        openid_connect = {
          OAUTH_PKCE_ENABLED = "True";
          APPS = [
            {
              provider_id = "oidc.domus.diffeq.com";
              name = "oidc.domus.diffeq.com";
              client_id = "paperless";
              # we add "secret" in systemd.services.paperless-web.script.
              settings.server_url = "https://${config.diffeq.hostNames.oidc}";
            }
          ];
        };
      };
    };

    package = pkgs.paperless-ngx;
  };

  # Add secret to PAPERLESS_SOCIALACCOUNT_PROVIDERS
  systemd.services.paperless-web.script = lib.mkBefore ''
    oidcSecret=$(< ${config.age.secrets.dex-paperless-secret.path})
    export PAPERLESS_SOCIALACCOUNT_PROVIDERS=$(
      ${pkgs.jq}/bin/jq <<< "$PAPERLESS_SOCIALACCOUNT_PROVIDERS" \
        --compact-output \
        --arg oidcSecret "$oidcSecret" '.openid_connect.APPS.[0].secret = $oidcSecret'
    )
  '';

  age.secrets = {
    fs-mi-go-paperless = {
      rekeyFile = config.diffeq.secretsPath + /fs/mi-go-paperless.age;
    };

    paperless-env = {
      rekeyFile = ./secrets/paperless-env.age;
      owner = config.services.paperless.user;
    };

    dex-paperless-secret = {
      rekeyFile = config.diffeq.secretsPath + /dex/paperless.age;
      owner = config.services.paperless.user;
      generator.script = "alnum";
    };
  };

  fileSystems."/mnt/paperless" = {
    device = "//mi-go.domus.diffeq.com/paperless";
    fsType = "cifs";
    options =
      let
        # this line prevents hanging on network split
        automount_opts = "x-systemd.automount,noauto,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s,x-systemd.after=network-online.target";

        # the defaults of a CIFS mount are not documented anywhere that I can see.
        # you can run "mount" after mounting to see what options were actually used.
        # cifsacl is required for the server-side permissions to show up correctly.
      in
      [
        "${automount_opts},cifsacl,uid=${config.services.paperless.user},credentials=${config.age.secrets.fs-mi-go-paperless.path}"
      ];
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
  services.caddy = {
    enable = true;
    virtualHosts."paperless.domus.diffeq.com" = {
      useACMEHost = "paperless.domus.diffeq.com";
      extraConfig = "reverse_proxy localhost:${toString config.services.paperless.port}";
    };
  };
}
