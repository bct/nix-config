{ self, config, inputs, lib, pkgs, ... }: {
  imports = [
    inputs.agenix.nixosModules.default

    "${self}/nixos/common/nix.nix"
    "${self}/nixos/common/headless.nix"

    "${self}/nixos/hardware/raspberry-pi"
    "${self}/nixos/hardware/raspberry-pi/hifiberry-dac-plus.nix"

    ./hardware-configuration.nix

    "${self}/nixos/modules/airsonic-refix"
    "${self}/nixos/modules/acme-zoneedit"
  ];

  networking.hostName = "stereo";

  systemd.network = {
    enable = true;
    networks."10-lan" = {
      matchConfig.Type = "ether";
      networkConfig.DHCP = "yes";
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

      music-path = ["/mnt/beets"];
      podcast-path = "/var/empty";
      scan-interval = 60; # minutes

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

  fileSystems."/mnt/beets" = {
    device = "//mi-go.domus.diffeq.com/beets";
    fsType = "cifs";
    options = let
      # this line prevents hanging on network split
      automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";

    in ["${automount_opts},guest"];
  };

  services.udev.extraRules = ''
    KERNEL=="gpiochip*", MODE:="0660", GROUP:="gpio"
  '';

  users.groups = {
    gpio = {};
  };

  services.airsonic-refix.enable = true;

  services.acme-zoneedit = {
    enable = true;
    hostname = "stereo.domus.diffeq.com";
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

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.05";
}
