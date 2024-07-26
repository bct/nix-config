{ self, inputs, config, ... }: {
  imports = [
    inputs.agenix.nixosModules.default
    inputs.disko.nixosModules.disko

    "${self}/nixos/common/nix.nix"
    "${self}/nixos/common/headless.nix"

    "${self}/nixos/hardware/vultr"

    ./disk-config.nix
    ./coredns-wgsd.nix
    ./container-networking.nix
    ./container-secrets.nix
    ./minio-instance.nix
    ./postgres.nix
    ./goatcounter.nix
    ./wiki.nix
    ./wireguard-viator.nix
    ./wireguard-conductum.nix

    ./static-site.nix

    ./borgmatic.nix
  ];

  # we'll configure these using disko.
  hardware.vultr.useSwapFile = false;
  hardware.vultr.setUpDisk = false;

  networking.hostName = "megahost-one";

  time.timeZone = "Etc/UTC";

  age.secrets = {
    s3-proxy-minio-root-credentials.file =
      ../../../secrets/s3-proxy-minio-root-credentials.age;

    password-postgres.file    = ../../../secrets/db/password-megahost-postgres.age;
    password-goatcounter.file = ../../../secrets/db/password-goatcounter.age;
    password-wikijs.file      = ../../../secrets/db/password-wikijs.age;
  };

  megahost.minio = {
    enable = true;
    instances = {
      "minio-escam-biz" = {
        minioDomain = "s3.escam.biz";
        buckets = [ "mosfet-novpet" ];
        hostAddress6 = "fc00::1";
        containerAddress6 = "fc00::f1";
        rootCredentialsPath = config.age.secrets.s3-proxy-minio-root-credentials.path;
      };

      "minio-diffeq-com" = {
        minioDomain = "s3.diffeq.com";
        buckets = [ "zardoz" "middel-salbyt" ];
        hostAddress6 = "fc00::2";
        containerAddress6 = "fc00::f2";
        rootCredentialsPath = config.age.secrets.s3-proxy-minio-root-credentials.path;
      };
    };
  };

  megahost.postgres = {
    databases = [ "goatcounter" "wiki-js" ];

    users = {
      postgres = {
        passwordFile = config.age.secrets.password-postgres.path;
      };

      goatcounter = {
        passwordFile = config.age.secrets.password-goatcounter.path;
        ensureDBOwnership = true;
      };

      wiki-js = {
        passwordFile = config.age.secrets.password-wikijs.path;
        ensureDBOwnership = true;
      };
    };
  };

  system.stateVersion = "24.05";
}
