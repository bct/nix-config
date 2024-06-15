{ containerName, minioDomain, consoleSubdomain ? "console", buckets, hostAddress6, containerAddress6, ... }:

{
  # set up a container to run minio
  containers.${containerName} = {
    autoStart = true;
    privateNetwork = true;

    hostAddress6 = hostAddress6;
    localAddress6 = containerAddress6;

    config = { config, pkgs, ... }: {
      system.stateVersion = "24.05";

      networking.firewall.allowedTCPPorts = [ 9000 9001 ];
    };
  };

  # the host reverse proxies to each container.
  services.caddy = {
    enable = true;

    # the admin console runs on container port 9001
    virtualHosts."${consoleSubdomain}.${minioDomain}".extraConfig = ''
      reverse_proxy [${containerAddress6}]:9001
    '';

    # buckets are accessible on container port 9000
    # TODO: use the acme-zoneedit module to get a wildcard certificate, so that
    # we don't need to explicitly list buckets here.
    virtualHosts.${minioDomain} = {
      serverAliases = map (bucket: "${bucket}.${minioDomain}") buckets;
      extraConfig = ''
        reverse_proxy [${containerAddress6}]:9000
      '';
    };
  };
}
