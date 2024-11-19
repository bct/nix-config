{ self, config, lib, pkgs, ... }: {
  imports = [
    "${self}/nixos/common/agenix-rekey.nix"

    "${self}/nixos/common/nix.nix"
    "${self}/nixos/common/headless.nix"
    "${self}/nixos/common/node-exporter.nix"

    "${self}/nixos/hardware/raspberry-pi"
    "${self}/nixos/hardware/raspberry-pi/hifiberry-dac-plus.nix"

    ./hardware-configuration.nix

    "${self}/nixos/modules/airsonic-refix"
    "${self}/nixos/modules/lego-proxy-client"
  ];

  networking.hostName = "stereo";
  networking.useNetworkd = true;

  systemd.network = {
    enable = true;

    networks."10-lan" = {
      matchConfig.Type = "ether";
      networkConfig.DHCP = "yes";
    };

    networks."10-wlan" = {
      matchConfig.Type = "wlan";
      linkConfig.Unmanaged = "yes";
    };
  };

  # avoid writing logs to disk, try to save the SD card
  services.journald.extraConfig = ''
    Storage=volatile
  '';

  time.timeZone = "America/Edmonton";

  environment.systemPackages = with pkgs; [
    cifs-utils

    onkyo-ri-send-command
  ];

  networking.firewall.enable = false;

  # grant myself access to the sound card.
  users.users.bct.extraGroups = ["audio" "gpio"];

  services.gonic = {
    enable = true;
    settings = {
      listen-addr = "0.0.0.0:4747";
      cache-path = "/var/cache/gonic";

      playlists-path = "/var/lib/gonic";
      music-path = ["/mnt/beets"];
      podcast-path = "/var/empty";
      scan-interval = 60; # minutes

      multi-value-genre = "delim ,";

      jukebox-enabled = true;
      jukebox-mpv-extra-args = "--audio-device=alsa/default:CARD=sndrpihifiberry";

      tls-cert = "${config.security.acme.certs."stereo.domus.diffeq.com".directory}/fullchain.pem";
      tls-key = "${config.security.acme.certs."stereo.domus.diffeq.com".directory}/key.pem";
    };
  };
  systemd.services.gonic.serviceConfig.SupplementaryGroups = ["audio" "acme"];
  systemd.services.gonic.serviceConfig.DeviceAllow = "char-alsa rw";
  systemd.services.gonic.serviceConfig.PrivateDevices = lib.mkForce false;

  systemd.services.subsonic-action-proxy = {
    description = "subsonic-action-proxy";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      ExecStart = let
        onkyo-ri = riCmds: "${pkgs.onkyo-ri-send-command}/bin/onkyo-ri-send-command 0 26 ${riCmds}";
      in
        ''${pkgs.subsonic-action-proxy}/bin/subsonic-action-proxy \
          -listen-addr 0.0.0.0:4646 \
          -subsonic-addr https://stereo.domus.diffeq.com:4747/ \
          -jukebox-set-command "${onkyo-ri "0xd9 0x20"}" \
          -add-rpc "/ssap/power ${onkyo-ri "0x4"}" \
          -add-rpc "/ssap/line-1 ${onkyo-ri "0x20"}" \
          -add-rpc "/ssap/volume-up ${onkyo-ri "0x203 0x203 0x203 0x203 0x203"}" \
          -add-rpc "/ssap/volume-down ${onkyo-ri "0x303 0x303 0x303 0x303 0x303"}"
        '';
      DynamicUser = true;
      SupplementaryGroups = ["gpio"];
    };
  };

  # this config was copied from the NixOS wiki.
  # sometimes when gonic tries to start it gets:
  #     Failed to mount /mnt/beets to /run/gonic/mnt/beets: No such device
  #
  # this can happen even if the network is working.
  fileSystems."/mnt/beets" = {
    device = "//mi-go.domus.diffeq.com/beets";
    fsType = "cifs";
    options = let
      # this line prevents hanging on network split
      automount_opts = "x-systemd.automount,noauto,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s,x-systemd.after=network-online.target";

    in ["${automount_opts},guest"];
  };

  services.udev.extraRules = ''
    KERNEL=="gpiochip*", MODE:="0660", GROUP:="gpio"
  '';

  users.groups = {
    gpio = {};
  };

  services.airsonic-refix.enable = true;

  services.lego-proxy-client = {
    enable = true;
    domains = [
      { domain = "stereo.domus.diffeq.com"; identity = config.age.secrets.lego-proxy-stereo.path; }
    ];
    dnsResolver = "ns5.zoneedit.com";
    email = "s+acme@diffeq.com";
  };

  age.secrets = {
    lego-proxy-stereo = {
      generator.script = "ssh-ed25519";
      rekeyFile = ../../../secrets/lego-proxy/stereo.age;
      owner = "acme";
      group = "acme";
    };
  };

  age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF+0o3CDs78/NW73QxiZ4gJtXgZ5U+NAu8o9lNhzmLwl";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.05";
}
