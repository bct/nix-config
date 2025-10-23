{ pkgs, ... }: {
  services.clipman.enable = true;
  programs.wofi.enable = true;

  programs.waybar = {
    enable = true;
    systemd.enable = true;
    settings = [{
      # "layer": "top", # Waybar at top layer
      # "position": "bottom", # Waybar position (top|bottom|left|right)
      height = 30; # Waybar height (to be removed for auto height)
      # "width": 1280, # Waybar width
      spacing = 4; # Gaps between modules (4px)

      # Choose the order of the modules
      modules-left = [
        "hyprland/workspaces"
        "hyprland/submap"
        "custom/media"
      ];

      modules-center = [
        "hyprland/window"
      ];

      modules-right = [
        "pulseaudio"
        "network"
        "cpu"
        "backlight"
        "battery"
        "clock"
        "tray"
      ];

      # Modules configuration
      "hyprland/workspaces" = {
        format = "{icon}";
        format-icons = {
          "1" = "";
          "2" = "";
          "3" = "";
          "4" = "󰭹";
          "5" = "";
          "6" = "";
          "urgent" = "";
          "default" = "";
        };
      };
      tray = {
        # "icon-size": 21,
        spacing = 10;
        # "icons": {
        #   "blueman": "bluetooth",
        #   "TelegramDesktop": "$HOME/.local/share/icons/hicolor/16x16/apps/telegram.png"
        # }
      };
      clock = {
        # "timezone": "America/New_York",
        tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        format-alt = "{:%Y-%m-%d}";
      };
      cpu = {
        format = "{usage}% ";
        tooltip = false;
      };
      backlight = {
        format = "{percent}% {icon}";
        format-icons = ["" "" "" "" "" "" "" "" ""];
      };
      battery = {
        states = {
          warning = 30;
          critical = 15;
        };
        format = "{capacity}% {icon}";
        format-full = "{capacity}% {icon}";
        format-charging = "{capacity}% 󰢝";
        format-plugged = "{capacity}% ";
        format-alt = "{time} {icon}";
        format-icons = ["" "" "" "" ""];
      };
      "network" = {
          # "interface" = "wlp2*", # (Optional) To force the use of this interface
          "format-wifi" = "{essid} ({signalStrength}%) ";
          "format-ethernet" = "{ipaddr}/{cidr} ";
          "tooltip-format" = "{ifname} via {gwaddr}";
          "format-linked" = "{ifname} (No IP) ";
          "format-disconnected" = "Disconnected ⚠";
          "format-alt" = "{ifname} = {ipaddr}/{cidr}";
      };
      pulseaudio = {
        format = "{volume}% {icon}";
        format-muted = "󰖁";
        format-icons = {
          "headphone" = "";
          "default" = ["" "" ""];
        };
        on-click = "pavucontrol";
      };
      "custom/media" = {
        "format" = "{icon} {text}";
        "return-type" = "json";
        "max-length" = 40;
        "format-icons" = {
          "spotify" = "";
          "default" = "🎜";
        };
        "escape" = true;
        "exec" = "$HOME/.config/waybar/mediaplayer.py 2> /dev/null"; # Script in resources folder
        # "exec" = "$HOME/.config/waybar/mediaplayer.py --player spotify 2> /dev/null" # Filter player based on name
      };
    }];

    style = ''
      * {
        font-family: "UbuntuMono Nerd Font";
        font-size: 13px;
      }

      window#waybar {
        background: rgba(40, 40, 40, 0.9);
        color: #ebdbb2;
      }

      #window {
        background: #458588;
        color: #ebdbb2;
        padding: 0 10px;
      }

      #workspaces button {
        padding: 0 5px;
        background: transparent;
        color: #ebdbb2;
        border: 0;
      }

      #workspaces button.active {
        background: rgba(203, 166, 247, 0.2);
      }

      #clock,
      #battery,
      #cpu,
      #backlight,
      #network,
      #pulseaudio,
      #tray,
      #bluetooth {
        padding: 0 10px;
        margin: 0 5px;
      }

      #battery.charging {
        color: #a6e3a1;
      }

      #battery.warning:not(.charging) {
        color: #fab387;
      }

      #battery.critical:not(.charging) {
        color: #f38ba8;
        animation: blink 0.5s linear infinite alternate;
      }

      @keyframes blink {
        to {
          background-color: #f38ba8;
          color: #1e1e2e;
        }
      }
    '';
  };

  home.packages = with pkgs; [
    brightnessctl

    # pkgs.hyprpaper
    hyprlock
    hypridle
    #pkgs.hyprpicker

    swww
    capitaine-cursors

    grim

    alacritty
    light

    playerctl
  ];

  home.pointerCursor = {
    package = pkgs.capitaine-cursors;
    name = "capitaine-cursors";
    size = 18;
    gtk.enable = true;
    x11.enable = true;
  };

  # Optional, hint Electron apps to use Wayland:
  home.sessionVariables.NIXOS_OZONE_WL = "1";

  wayland.windowManager.hyprland = {
    enable = true; # enable Hyprland

    # If you use the Home Manager module, make sure to disable the systemd integration, as it
    # conflicts with uwsm.
    # https://wiki.hypr.land/Useful-Utilities/Systemd-start/
    #systemd.enable = false;

    settings.env = [
      "XCURSOR_THEME,capitaine-cursors"
      "XCURSOR_SIZE,18"
    ];

    # https://github.com/hyprwm/Hyprland/blob/main/example/hyprland.conf
    extraConfig = ''
      ###################
      ### MY PROGRAMS ###
      ###################

      # See https://wiki.hypr.land/Configuring/Keywords/

      # Set programs that you use
      $terminal = alacritty
      $menu = wofi --show run


      #################
      ### AUTOSTART ###
      #################

      # Autostart necessary processes (like notifications daemons, status bars, etc.)
      # Or execute your favorite apps at launch like this:

      # exec-once = $terminal
      # exec-once = nm-applet &
      # exec-once = waybar & hyprpaper & firefox


      #####################
      ### LOOK AND FEEL ###
      #####################

      # See https://wiki.hypr.land/Configuring/Dwindle-Layout/ for more
      dwindle {
          pseudotile = true # Master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
          preserve_split = true # You probably want this
      }

      # See https://wiki.hypr.land/Configuring/Master-Layout/ for more
      master {
          new_status = master
      }

      # https://wiki.hypr.land/Configuring/Variables/#misc
      misc {
          force_default_wallpaper = -1 # Set to 0 or 1 to disable the anime mascot wallpapers
          disable_hyprland_logo = true # disable the random hyprland logo / anime girl background
      }

      #############
      ### INPUT ###
      #############

      # https://wiki.hypr.land/Configuring/Variables/#input
      input {
          kb_layout = us
          kb_variant = dvorak
          kb_model =
          kb_options =
          kb_rules =

          follow_mouse = 1

          sensitivity = 0 # -1.0 - 1.0, 0 means no modification.

          touchpad {
              natural_scroll = false
          }
      }

      ###################
      ### KEYBINDINGS ###
      ###################

      # See https://wiki.hypr.land/Configuring/Keywords/
      $mainMod = SUPER # Sets "Windows" key as main modifier

      # Example binds, see https://wiki.hypr.land/Configuring/Binds/ for more
      bind = SHIFT ALT, Return, exec, $terminal
      bind = SHIFT ALT, C, killactive,
      bind = SHIFT ALT, Q, exit,
      #bind = $mainMod, V, togglefloating,
      bind = $mainMod, P, exec, $menu
      #bind = $mainMod, P, pseudo, # dwindle
      bind = $mainMod, J, togglesplit, # dwindle

      bind = $mainMod, F, fullscreenstate, 1 0

      # Move focus with mainMod + arrow keys
      bind = ALT, h, movefocus, l
      bind = ALT, j, movefocus, d
      bind = ALT, k, movefocus, u
      bind = ALT, l, movefocus, r

      # Return to previous workspace
      bind = ALT, r, workspace, previous

      # Switch workspaces with mainMod + [0-9]
      bind = $mainMod, 1, workspace, 1
      bind = $mainMod, 2, workspace, 2
      bind = $mainMod, 3, workspace, 3
      bind = $mainMod, 4, workspace, 4
      bind = $mainMod, 5, workspace, 5
      bind = $mainMod, 6, workspace, 6
      bind = $mainMod, 7, workspace, 7
      bind = $mainMod, 8, workspace, 8
      bind = $mainMod, 9, workspace, 9
      bind = $mainMod, 0, workspace, 10

      # Move active windowGto a workspace with mainMod + SHIFT + [0-9]
      bind = $mainMod SHIFT, 1, movetoworkspace, 1
      bind = $mainMod SHIFT, 2, movetoworkspace, 2
      bind = $mainMod SHIFT, 3, movetoworkspace, 3
      bind = $mainMod SHIFT, 4, movetoworkspace, 4
      bind = $mainMod SHIFT, 5, movetoworkspace, 5
      bind = $mainMod SHIFT, 6, movetoworkspace, 6
      bind = $mainMod SHIFT, 7, movetoworkspace, 7
      bind = $mainMod SHIFT, 8, movetoworkspace, 8
      bind = $mainMod SHIFT, 9, movetoworkspace, 9
      bind = $mainMod SHIFT, 0, movetoworkspace, 10

      # Example special workspace (scratchpad)
      bind = $mainMod, S, togglespecialworkspace, magic
      bind = $mainMod SHIFT, S, movetoworkspace, special:magic

      # Scroll through existing workspaces with mainMod + scroll
      bind = $mainMod, mouse_down, workspace, e+1
      bind = $mainMod, mouse_up, workspace, e-1

      # Tabbed layout
      bind = $mainMod, T, togglegroup
      bind = $mainMod CTRL, h, changegroupactive, b
      bind = $mainMod CTRL, l, changegroupactive, f
      bind = $mainMod SHIFT, h, movewindoworgroup, l
      bind = $mainMod SHIFT, l, movewindoworgroup, r
      bind = $mainMod SHIFT, k, movewindoworgroup, u
      bind = $mainMod SHIFT, j, movewindoworgroup, d

      # Move/resize windows with mainMod + LMB/RMB and dragging
      bindm = $mainMod, mouse:272, movewindow
      bindm = $mainMod, mouse:273, resizewindow

      # Laptop multimedia keys for volume and LCD brightness
      bindel = ,XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+
      bindel = ,XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
      bindel = ,XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
      bindel = ,XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
      bindel = ,XF86MonBrightnessUp, exec, brightnessctl -e4 -n2 set 5%+
      bindel = ,XF86MonBrightnessDown, exec, brightnessctl -e4 -n2 set 5%-

      # Requires playerctl
      bindl = , XF86AudioNext, exec, playerctl next
      bindl = , XF86AudioPause, exec, playerctl play-pause
      bindl = , XF86AudioPlay, exec, playerctl play-pause
      bindl = , XF86AudioPrev, exec, playerctl previous


      ##############################
      ### WINDOWS AND WORKSPACES ###
      ##############################

      # See https://wiki.hypr.land/Configuring/Window-Rules/ for more
      # See https://wiki.hypr.land/Configuring/Workspace-Rules/ for workspace rules

      # Example windowrule
      # windowrule = float,class:^(kitty)$,title:^(kitty)$

      # Ignore maximize requests from apps. You'll probably like this.
      windowrule = suppressevent maximize, class:.*

      # Fix some dragging issues with XWayland
      windowrule = nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0

      # Chrome on workspace 2 gets grouped
      windowrule = group set,workspace:2,class:^(chromium-browser)$
      # Jellyfin opens on workspace 6
      windowrule = workspace 6 silent,class:^(chromium-browser)$,title:^(Jellyfin)$
    '';
  };
}
