{ ... }:
{
  services.hypridle = {
    enable = true;
  };

  xdg.configFile."hypr/hypridle.conf".text = ''
    general {
        lock_cmd = pidof hyprlock || hyprlock       # avoid starting multiple hyprlock instances.
        before_sleep_cmd = loginctl lock-session    # lock before suspend.
        after_sleep_cmd = hyprctl dispatch dpms on  # to avoid having to press a key twice to turn on the display.
    }

    listener {
        timeout = 150                                # 2.5min.
        on-timeout = brightnessctl -s set 10         # set monitor backlight to minimum, avoid 0 on OLED monitor.
        on-resume = brightnessctl -r                 # monitor backlight restore.
    }

    listener {
        timeout = 300                                 # 5min
        on-timeout = loginctl lock-session            # lock screen when timeout has passed
    }

    listener {
        timeout = 330                                                     # 5.5min
        on-timeout = hyprctl dispatch dpms off                            # screen off when timeout has passed
        on-resume = hyprctl dispatch dpms on && brightnessctl -r          # screen on when activity is detected after timeout has fired.
    }
  '';

  programs.hyprlock = {
    enable = true;
    extraConfig = ''
      $font = UbuntuMono

      general {
          hide_cursor = true
      }

      animations {
          enabled = true
          bezier = linear, 1, 1, 0, 0
          animation = fadeIn, 1, 5, linear
          animation = fadeOut, 1, 5, linear
          animation = inputFieldDots, 1, 2, linear
      }

      background {
          color = rgb(282828)
      }

      input-field {
          size = 600, 90

          rounding = 0
          placeholder_text =
          outline_thickness = 2

          outer_color = rgb(d79921)
          inner_color = rgb(1d2021)
          font_color = rgb(ebdbb2)
          check_color = rgb(98971a)
          fail_color = rgb(cc241d)

          fail_text = <i>lol no <b>($ATTEMPTS)</b></i>

          dots_size = 0.2
          dots_rounding = 0
          dots_spacing = 0.65
      }

      # TIME
      label {
          monitor =
          text = $TIME # ref. https://wiki.hyprland.org/Hypr-Ecosystem/hyprlock/#variable-substitution
          font_size = 90
          font_family = $font
          color = rgb(ebdbb2)

          position = -100, -20
          halign = right
          valign = top
      }

      # DATE
      label {
          monitor =
          text = cmd[update:60000] date +"%A %m/%d" # update every 60 seconds
          font_size = 25
          font_family = $font
          color = rgb(8ec07c)

          position = -100, -130
          halign = right
          valign = top
      }
    '';
  };
}
