{ pkgs, ... }:
{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;

    settings = {
      # https://git.kernel.org/pub/scm/bluetooth/bluez.git/tree/src/main.conf
      General = {
        # Major Device Class: A/V, Minor DC: Loudspeaker
        # This only (?) affects the way clients display the device.
        Class = "0x000414";
        # https://github.com/TuringTestTwister/mediaserver/blob/a4b8725fb28c015cffac34535bccfc099764e6ce/mediaserver-rpi4/bluetooth-auto-pair.nix#L26
        # allow re-pairing without user interaction
        JustWorksRepairing = "always";
        # Pairing always on
        AlwaysPairable = "true";
        # Don't disable discoverability after timeout
        DiscoverableTimeout = "0";
        # Faster but uses more power
        FastConnectable = true;
        Experimental = true;
      };
      Policy = {
        # enable all controllers when they are found.
        AutoEnable = true;
      };
    };
  };

  systemd.services.bluetooth-auto-pair = {
    wantedBy = [
      "bluetooth.service"
    ];
    after = [
      "bluetooth.service"
    ];
    bindsTo = [
      "bluetooth.service"
    ];
    serviceConfig = {
      Type = "simple";
      ExecStart = pkgs.writeShellScript "exec-start" ''
        ${pkgs.bluez}/bin/bluetoothctl <<EOF
        discoverable on
        pairable on
        EOF

        ${pkgs.coreutils}/bin/yes | ${pkgs.bluez-tools}/bin/bt-agent -c NoInputNoOutput
      '';
      ExecStop = pkgs.writeShellScript "exec-stop" ''
        kill -s SIGINT $MAINPID
      '';
      Restart = "on-failure";
    };
  };
}
