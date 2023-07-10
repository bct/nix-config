{ containerName, minioDomain, consoleSubdomain ? "console", buckets, hostAddress6, containerAddress6, rootCredentialsPath, ... }:

{
  containers.${containerName} = {
    autoStart = true;
    privateNetwork = true;

    bindMounts = {
      "/tmp/minio-root-credentials" = {
        hostPath = rootCredentialsPath;
        isReadOnly = true;
     };
    };

    hostAddress6 = hostAddress6;
    localAddress6 = containerAddress6;

    config = { config, pkgs, ... }: {
      system.stateVersion = "23.05";

      networking.firewall.allowedTCPPorts = [ 9000 9001 ];

      services.minio = {
        enable = true;
        rootCredentialsFile = "/tmp/minio-root-credentials";
      };
      systemd.services.minio.environment = {
        MINIO_DOMAIN = minioDomain;

        # avoid exposing our console URL.
        # it dosen't really matter and it's easy to guess but /shrug
        MINIO_BROWSER_REDIRECT_URL = "https://aws.amazon.com/s3/";
      };
    };
  };

  services.caddy = {
    enable = true;

    virtualHosts."${consoleSubdomain}.${minioDomain}".extraConfig = ''
      reverse_proxy [${containerAddress6}]:9001
    '';

    # unfortunately I'm not sure how to get a wildcard certificate, since it needs DNS support
    virtualHosts.${minioDomain} = {
      serverAliases = map (bucket: "${bucket}.${minioDomain}") buckets;
      extraConfig = ''
        reverse_proxy [${containerAddress6}]:9000
      '';
    };
  };
}
