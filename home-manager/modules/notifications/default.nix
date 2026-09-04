{ pkgs, ... }:
{
  home.packages = [
    pkgs.dunst # dunstify
  ];

  services.mako = {
    enable = true;

    # https://github.com/emersion/mako/blob/master/doc/mako.5.scd
    settings = {
      anchor = "bottom-right";
      default-timeout = 7500;
      outer-margin = "10,0";

      # gruvbox
      background-color = "#3c3836cc";
      text-color = "#ebdbb2";
      border-color = "#83a598cc";
      border-radius = 2;
      border-size = 1;
      layer = "overlay";

      "summary=\"Claude Code\"" =
        let
          sound = pkgs.writeShellScript "play-sound" ''
            ${pkgs.pipewire}/bin/pw-play --volume 1.0 ${pkgs.sound-theme-freedesktop}/share/sounds/freedesktop/stereo/complete.oga
          '';
        in
        {
          on-notify = "exec ${toString sound}";
        };
    };
  };
}
