{ self, inputs, outputs, lib, ... }: {
  imports = [
    inputs.agenix.nixosModules.default
    inputs.agenix-rekey.nixosModules.default

    inputs.disko.nixosModules.disko

    "${self}/nixos/common/nix.nix"
    "${self}/nixos/common/headless.nix"

    ./hardware-configuration.nix
    ./disk-config.nix

    inputs.microvm.nixosModules.host

    ./guests/prometheus.nix
    ./guests/torrent-scraper.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  time.timeZone = "Etc/UTC";

  networking.hostName = "yuggoth";
  networking.useNetworkd = true;

  # https://astro.github.io/microvm.nix/simple-network.html
  systemd.network.enable = true;

  # bridge ethernet and VM interfaces
  systemd.network.networks."10-lan" = {
    matchConfig.Name = ["enp5s0f0" "vm-*"];
    networkConfig = {
      Bridge = "br0";
    };
  };

  systemd.network.netdevs."br0" = {
    netdevConfig = {
      Name = "br0";
      Kind = "bridge";
    };
  };

  systemd.network.networks."10-lan-bridge" = {
    matchConfig.Name = "br0";
    networkConfig.DHCP = "yes";
    linkConfig.RequiredForOnline = "routable";
  };

  microvm.host.enable = true;

  # https://astro.github.io/microvm.nix/faq.html#how-to-centralize-logging-with-journald
  systemd.tmpfiles.rules = [
    # create a symlink of each MicroVM's journal under the host's /var/log/journal
    "L+ /var/log/journal/b42e25167b6bc7ca726ea9f41ce5ffcb - - - - /var/lib/microvms/miniflux/journal/b42e25167b6bc7ca726ea9f41ce5ffcb"
    "L+ /var/log/journal/6621b60f7f7ac43dca44e143eb0578a8 - - - - /var/lib/microvms/prometheus/journal/6621b60f7f7ac43dca44e143eb0578a8"
    "L+ /var/log/journal/e5b7d8199d4a4a34fb6748faef793248 - - - - /var/lib/microvms/torrent-scraper/journal/e5b7d8199d4a4a34fb6748faef793248"
  ];

  age.secrets = let
    generate-ssh-host-key = hostName: {pkgs, file, ...}: ''
        ${pkgs.openssh}/bin/ssh-keygen -qt ed25519 -N "" -C "root@${hostName}" -f ${lib.escapeShellArg (lib.removeSuffix ".age" file)}
        priv=$(${pkgs.coreutils}/bin/cat ${lib.escapeShellArg (lib.removeSuffix ".age" file)})
        ${pkgs.coreutils}/bin/shred -u ${lib.escapeShellArg (lib.removeSuffix ".age" file)}
        echo "$priv"
      '';
  in {
    ssh-host-miniflux = {
      path = "/run/agenix-vms/miniflux/ssh-host";
      symlink = false; # the VM can't resolve the symlink
      rekeyFile = ../../../secrets/ssh/host-miniflux.age;
      generator.script = generate-ssh-host-key "miniflux";
    };

    ssh-host-prometheus = {
      path = "/run/agenix-vms/prometheus/ssh-host";
      symlink = false; # the VM can't resolve the symlink
      rekeyFile = ../../../secrets/ssh/host-prometheus.age;
      generator.script = generate-ssh-host-key "prometheus";
    };

    ssh-host-torrent-scraper = {
      path = "/run/agenix-vms/torrent-scraper/ssh-host";
      symlink = false; # the VM can't resolve the symlink
      rekeyFile = ../../../secrets/ssh/host-torrent-scraper.age;
      generator.script = generate-ssh-host-key "torrent-scraper";
    };
  };

  age.rekey = {
    masterIdentities = ["/home/bct/.ssh/id_rsa"];
    storageMode = "local";
    localStorageDir = ../../.. + "/secrets/rekeyed/yuggoth";
    hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFVYcCxqBIE6ppS6n7VQb3Qs4w1gEYtNhTdKu+21XO82";
  };


  microvm.vms.miniflux = {
    specialArgs = { inherit self inputs outputs; };
    config = {
      imports = [ ./guests/miniflux.nix ];
    };
  };

  system.stateVersion = "24.05";
}
