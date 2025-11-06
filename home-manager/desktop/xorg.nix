{ config, pkgs, ... }:

let
  # https://gist.github.com/erfanio/eec67e1a538eeef3ff72562412030b6a
  # "adapted from xss-lock documantation"
  # https://bitbucket.org/raymonad/xss-lock/src/1e158fb20108058dbd62bd51d8e8c003c0a48717/doc/dim-screen.sh
  dim-screen = pkgs.writeShellScript "dim-screen" ''
    set -euo pipefail

    # Brightness will be lowered to this value.
    min_brightness=0

    ###############################################################################

    get_brightness() {
        ${pkgs.light}/bin/light -G
    }

    set_brightness() {
        ${pkgs.light}/bin/light -S $1
    }

    trap "exit 0" INT TERM
    # kill background processes and set the brightness back to the original value
    trap "kill \$(jobs -p); set_brightness $(get_brightness);" EXIT

    set_brightness $min_brightness

    sleep 2147483647 &
    wait
  '';
in {
  imports = [
    ../modules/dunst
    ../modules/rofi
    ../modules/hyprland

    ./screen-break-reminder.nix
  ];

  xsession = {
    enable = true;
    initExtra = ''
      # Dim the screen after three minutes of inactivity.
      # Lock the screen two minutes later.
      xset s 180 120

      # hook up sxlock to the screen saver extension and systemd's login manager
      xss-lock -n "${dim-screen}" -- sxlock &

      # set desktop background
      ~/.fehbg &

      # set minimum brightness higher than 0
      ${pkgs.light}/bin/light -N 0.1
    '';
  };

  fonts.fontconfig.enable = true;

  # Get AppImages (cura) working.
  # "For the sandboxed apps to work correctly, desktop integration portals need to be installed."
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      config.wayland.windowManager.hyprland.portalPackage
    ];
  };
}
