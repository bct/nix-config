{ lib, pkgs, ... }: {
  imports = [
    ../common/nix.nix
    ../common/headless.nix

    ./hardware-configuration.nix

    ../hardware/raspberry-pi
    ../hardware/raspberry-pi/hifiberry-dac-plus.nix
  ];

  networking.hostName = "stereo";

  networking.networkmanager = {
    enable = true;
    unmanaged = ["wlan0"];
  };

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
    };
  };
  systemd.services.gonic.serviceConfig.SupplementaryGroups = ["audio"];
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
          -subsonic-addr http://localhost:4747/ \
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

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.05";
}
