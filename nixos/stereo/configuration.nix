args@{ inputs, outputs, lib, config, pkgs, options, ... }: {
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
