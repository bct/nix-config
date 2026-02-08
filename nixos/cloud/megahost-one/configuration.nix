{
  self,
  inputs,
  config,
  ...
}:
{
  imports = [
    inputs.disko.nixosModules.disko

    "${self}/nixos/common/nix.nix"
    "${self}/nixos/common/headless.nix"
    "${self}/nixos/common/agenix-rekey.nix"

    "${self}/nixos/hardware/vultr"

    ./disk-config.nix
    ./coredns-wgsd.nix
    ./container-networking.nix
    ./container-secrets.nix
    ./minio-instance.nix
    ./netbird.nix
    ./postgres.nix
    ./goatcounter.nix
    ./minecraft.nix
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

  # TODO: can we use agenix-rekey to bootstrap the host SSH key?
  age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJAbD0X8eQfKiG2rYYcZ6dVdRHQaRK8DrFz7YaLzHQx2";
  age.secrets = {
    s3-proxy-minio-root-credentials.rekeyFile =
      config.diffeq.secretsPath + /s3-proxy-minio-root-credentials.age;

    password-postgres.rekeyFile = config.diffeq.secretsPath + /db/password-megahost-postgres.age;
    password-goatcounter.rekeyFile = config.diffeq.secretsPath + /db/password-goatcounter.age;
    password-wikijs.rekeyFile = config.diffeq.secretsPath + /db/password-wikijs.age;
  };

  megahost.minio = {
    enable = true;
    instances = {
      minio-escam-biz = {
        minioDomain = "s3.escam.biz";
        buckets = [ "mosfet-novpet" ];
        rootCredentialsPath = config.age.secrets.s3-proxy-minio-root-credentials.path;
      };

      minio-diffeq-com = {
        minioDomain = "s3.diffeq.com";
        buckets = [
          "zardoz"
          "middel-salbyt"
        ];
        rootCredentialsPath = config.age.secrets.s3-proxy-minio-root-credentials.path;
      };
    };
  };

  megahost.postgres = {
    databases = [
      "goatcounter"
      "wiki-js"
    ];

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

  megahost.container-network = {
    # an network for containers that communicate with the host & each other.
    bridge-internal = {
      # https://unique-local-ipv6.com/#
      prefix6 = "fdf0:4612:c105";

      containers = {
        postgres = {
          suffix6 = "2";
        };
        goatcounter = {
          suffix6 = "3";
        };
        wiki = {
          suffix6 = "4";
        };
        minio-escam-biz = {
          suffix6 = "6";
        };
        minio-diffeq-com = {
          suffix6 = "7";
        };
      };
    };
  };

  systemd.tmpfiles.rules = [
    # ensure that /srv/data exists, and is only accessible by root.
    # this directory contains bind mounts with data that is only protected by having a
    # private parent directory.
    # "-" means no automatic cleanup.
    "d /srv/data 0700 root root -"
  ];

  services.caddy = {
    enable = true;
    virtualHosts."photos.diffeq.com".extraConfig = ''
      reverse_proxy https://immich.domus.diffeq.com {
        header_up Host {upstream_hostport}
      }
    '';
    virtualHosts."books.diffeq.com".extraConfig = ''
      reverse_proxy https://books.domus.diffeq.com {
        header_up Host {upstream_hostport}
      }
    '';
  };

  system.stateVersion = "24.05";
}
