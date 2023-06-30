args@{ inputs, outputs, lib, config, pkgs, options, ... }: {
  imports = [
    ../common/nix.nix
    ../common/headless.nix

    ./hardware-configuration.nix

    ../hardware/raspberry-pi
    ../hardware/raspberry-pi/hifiberry-dac-plus
  ];

  networking.hostName = "stereo";

  networking.networkmanager = {
    enable = true;
    unmanaged = ["wlan0"];
  };

  time.timeZone = "America/Edmonton";

  environment.systemPackages = with pkgs; [
    cifs-utils
  ];

  networking.firewall.enable = false;

  # grant myself access to the sound card.
  users.users.bct.extraGroups = ["audio"];

  services.gonic = {
    enable = true;
    settings = {
      listen-addr = "0.0.0.0:4747";
      cache-path = "/var/cache/gonic";

      music-path = ["/mnt/beets"];
      podcast-path = "/var/empty";
      scan-interval = 60; # minutes

      jukebox-enabled = true;
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

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.05";
}
