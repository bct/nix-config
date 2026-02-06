{ config, pkgs, ... }:
{
  networking.firewall.allowedTCPPorts = [
    config.services.mpd.network.port
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
}
