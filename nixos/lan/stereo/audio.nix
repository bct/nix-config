# https://wiki.nixos.org/wiki/PipeWire
{ pkgs, ... }:
let
  onkyo-ri = riCmds: "${pkgs.onkyo-ri-send-command}/bin/onkyo-ri-send-command 0 26 ${riCmds}";
in
{
  # rtkit (optional, recommended) allows Pipewire to use the realtime scheduler for increased performance.
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;

    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;

    systemWide = true;
    wireplumber = {
      enable = true;
      extraConfig = {
        # i don't want to use the onboard headphone jack, i want to use the hifiberry.
        "10-deprioritize-onboard" = {
          "monitor.alsa.rules" = [
            {
              matches = [
                {
                  "node.name" = "alsa_output.platform-3f00b840.mailbox.stereo-fallback";
                }
              ];

              actions.update-props = {
                #"node.disabled" = true;
                "priority.session" = 100;
                "priority.driver" = 100;
              };
            }
          ];
        };

        # route incoming bluetooth audio to the sound card
        "50-bluez" = {
          "monitor.bluez.properties" = {
            "bluez5.enable-sbc-xq" = true;
            "bluez5.enable-hw-volume" = true;
            "bluez5.enable-msbc" = false;
            "bluez5.codecs" = [
              "sbc_xq"
              "aac"
            ];
            "bluez5.roles" = [ "a2dp_sink" ];
          };
        };
      };
    };
  };

  # Start pipewire on system boot
  systemd.services.pipewire.wantedBy = [ "multi-user.target" ];

  # when a bluetooth client connects, turn on the stereo and switch to line1
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="bluetooth", RUN+="${onkyo-ri "0xd9 0x20"}"
  '';

  users.users.bct.extraGroups = [ "pipewire" ];
  users.users.mpd.extraGroups = [ "pipewire" ];
}
