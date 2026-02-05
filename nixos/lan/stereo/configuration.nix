{
  self,
  pkgs,
  config,
  ...
}:
{
  imports = [
    "${self}/nixos/common/agenix-rekey.nix"

    "${self}/nixos/common/nix.nix"
    "${self}/nixos/common/headless.nix"
    "${self}/nixos/common/node-exporter.nix"

    "${self}/nixos/hardware/raspberry-pi"
    "${self}/nixos/hardware/raspberry-pi/hifiberry-dac-plus.nix"

    ./hardware-configuration.nix

    "${self}/nixos/modules/airsonic-refix"

    ./audio.nix
    ./bluetooth.nix
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

  networking.firewall.allowedTCPPorts = [
    4646 # subsonic-action-proxy
    config.services.mpd.network.port
  ];

  # grant myself access to the sound card.
  users.users.bct.extraGroups = [
    "audio"
    "gpio"
  ];

  services.mpd = {
    enable = true;
    network.listenAddress = "[::]"; # the default ("any") does not bind to IPv6
    musicDirectory = "/mnt/beets";

    extraConfig = ''
      audio_output {
        type "alsa"
        name "hifiberry"
        device "hw:1,0" # "hw:card,device", found using aplay -l
        mixer_control "Master"
      }
    '';
  };

  # TODO: replace this now that we're not using jukebox mode
  systemd.services.subsonic-action-proxy = {
    description = "subsonic-action-proxy";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      ExecStart =
        let
          onkyo-ri = riCmds: "${pkgs.onkyo-ri-send-command}/bin/onkyo-ri-send-command 0 26 ${riCmds}";
        in
        ''
          ${pkgs.subsonic-action-proxy}/bin/subsonic-action-proxy \
                    -listen-addr 0.0.0.0:4646 \
                    -subsonic-addr https://stereo.domus.diffeq.com:4747/ \
                    -jukebox-set-command "${onkyo-ri "0xd9 0x20"}" \
                    -add-rpc "/ssap/power ${onkyo-ri "0x4"}" \
                    -add-rpc "/ssap/line-1 ${onkyo-ri "0x20"}" \
                    -add-rpc "/ssap/volume-up ${onkyo-ri "0x203 0x203 0x203 0x203 0x203"}" \
                    -add-rpc "/ssap/volume-down ${onkyo-ri "0x303 0x303 0x303 0x303 0x303"}"
        '';
      DynamicUser = true;
      SupplementaryGroups = [ "gpio" ];
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
    options =
      let
        # this line prevents hanging on network split
        automount_opts = "x-systemd.automount,noauto,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s,x-systemd.after=network-online.target";

      in
      [ "${automount_opts},guest" ];
  };

  services.udev.extraRules = ''
    KERNEL=="gpiochip*", MODE:="0660", GROUP:="gpio"
  '';

  users.groups = {
    gpio = { };
  };

  # services.airsonic-refix.enable = true;

  systemd.timers.mpc-update = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "hourly";
      Unit = "mpc-update.service";
    };
  };

  systemd.services.mpc-update = {
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "mpc-update" ''
        bt_connected=$(${pkgs.bluez}/bin/bluetoothctl devices Connected)
        if [ -n "$bt_connected" ]; then
          ${pkgs.mpc}/bin/mpc update
        else
          # if anybody is connected they might be playing audio.
          # our bluetooth is a little unstable, and running an "mpc update" might push
          # it over the edge.
          echo "not running mpc update because BT devices are connected:"
          echo "$bt_connected"
        fi
      '';
    };
  };

  age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF+0o3CDs78/NW73QxiZ4gJtXgZ5U+NAu8o9lNhzmLwl";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.05";
}
