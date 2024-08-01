{ self, config, inputs, ... }: {
  imports = [
    inputs.agenix.nixosModules.default

    "${self}/nixos/common/nix.nix"
    "${self}/nixos/common/headless.nix"

    ./hardware-configuration.nix

    "${self}/nixos/modules/acme-zoneedit"

    ./immich.nix
    ./metrics.nix
    ./miniflux.nix
  ];

  networking.hostName = "yuurei";
  networking.useNetworkd = true;

  time.timeZone = "Etc/UTC";

  services.acme-zoneedit = {
    enable = true;
    hostnames = ["mi-go.domus.diffeq.com" "router.domus.diffeq.com" "yuurei.domus.diffeq.com"];
    email = "s+acme@diffeq.com";
    credentialsFile = config.age.secrets.zoneedit.path;
  };

  age.secrets = {
    zoneedit = {
      file = ../../../secrets/zoneedit.age;
      owner = "acme";
      group = "acme";
      mode = "600";
    };
  };

  services.iperf3 = {
    enable = true;
    openFirewall = true;
  };

  system.stateVersion = "23.05";
}
