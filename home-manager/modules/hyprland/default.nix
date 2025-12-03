{ config, inputs, lib, pkgs, ... }: let
  workspaces = [
    { name = "mon";   icon = ""; }
    { name = "web";   icon = ""; }
    { name = "proj";  icon = ""; }
    { name = "chat";  icon = "󰭹"; }
    { name = "mail";  icon = ""; }
    { name = "notes"; icon = "󰷈"; }
    { name = "kino";  icon = ""; }
    { name = "3dp";   icon = ""; }
    { name = "zap";   icon = ""; }
    { name = "host";  icon = ""; }
    { name = "img";   icon = ""; }
  ];

  # prepare a list of workspaces for grid-select -d.
  # format: "value,display"
  workspaceSelectors = pkgs.writeText "hyprland-workspaces-selectors" (
    lib.concatImapStrings
      (wsId: ws: "${toString wsId},${ws.icon} ${ws.name}" + "\n")
      workspaces
  );

  gridselect-workspace = pkgs.writeShellApplication {
    name = "gridselect-workspace";
    runtimeInputs = [
      config.wayland.windowManager.hyprland.package
      inputs.grid-select.packages.${pkgs.system}.default
    ];
    text = ''
      dispatcher=$1

      # open the grid select to choose a workspace.
      workspace_id=$(grid-select -d , <${workspaceSelectors})

      # was a workspace selected?
      if [ -n "$workspace_id" ]; then
        # switch to the selected workspace.
        hyprctl dispatch "$dispatcher" "$workspace_id"
      fi
    '';
  };
in {
  services.cliphist.enable = true;

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
      ];

      modules-center = [
        "hyprland/window"
      ];

      modules-right = [
        "pulseaudio"
        "network#wireless"
        "network#wg"
        "cpu"
        "backlight"
        "battery"
        "clock"
        "tray"
      ];

      # Modules configuration
      "hyprland/workspaces" = let
        ws-icons = builtins.listToAttrs (map (ws: { name = ws.name; value = ws.icon; }) workspaces);
      in {
        format = "{icon}";
        format-icons = ws-icons // {
          "music" = "";
          "urgent" = "";
          "default" = "";
        };
        show-special = true;
        special-visible-only = true;
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
        # add extra space on the right because it looks bad with the background
        # when critical
        format = "{capacity}% {icon} ";
        format-full = "{capacity}% {icon} ";
        format-charging = "{capacity}% 󰢝" ;
        format-plugged = "{capacity}%  ";
        format-alt = "{time} {icon} ";
        format-icons = ["" "" "" "" ""];
      };
      "network#wireless" = {
          "interface" = "wlp*";
          "format-wifi" = "{signalStrength}% ";
          "format-ethernet" = "{ipaddr}/{cidr} ";
          "tooltip-format" = "{ifname} via {gwaddr}";
          "format-linked" = "{ifname} (No IP) ";
          "format-disconnected" = "Disconnected ⚠";
          "format-alt" = "{ifname} = {ipaddr}/{cidr}";
      };
      "network#wg" = {
          "interface" = "wg0";
          "format" = "󰌾";
          "tooltip-format" = "{ifname}";
          "format-linked" = "{ifname} (No IP) 󰌾";
          "format-disconnected" = "";
          "format-alt" = "{ifname} = {ipaddr}/{cidr} 󰌾";
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

      #workspaces {
        padding-left: 3px;
      }

      #workspaces button {
        background: transparent;
        color: #ebdbb2;
        margin: 0;
        padding: 0 9px 0 5px;
        border: 0;
        border-radius: 0;
      }

      #workspaces button:hover {
        border: 0;
        box-shadow: none;
      }

      #workspaces button.active {
        background: #689d6a;
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
        color: #d65d0e;
      }

      #battery.critical:not(.charging) {
        color: #d65d0e;
        animation: blink 0.5s linear infinite alternate;
      }

      @keyframes blink {
        to {
          background-color: #d65d0e;
          color: #1e1e2e;
        }
      }
    '';
  };

  home.packages = with pkgs; [
    brightnessctl

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
    extraConfig = let
      # we could use named workspaces, but this allows us to specify the order
      workspaceRules = lib.concatLines (lib.imap1 (i: ws: "workspace = ${toString i}, defaultName:${ws.name}") workspaces);
    in ''
      ################
      ### MONITORS ###
      ################

      # See https://wiki.hypr.land/Configuring/Monitors/
      monitor = desc:Dell Inc. DELL U2515H FJYC778B0XLL, preferred, auto, 1.333
      monitor = ,preferred,auto,auto

      ###################
      ### MY PROGRAMS ###
      ###################

      # See https://wiki.hypr.land/Configuring/Keywords/

      # Set programs that you use
      $terminal = alacritty
      $menu = rofi-launcher


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

      decoration {
        # when a special workspace is open, dim everything else a little more
        dim_special = 0.4
      }

      group {
        col.border_active = rgb(ffffff)
        col.border_inactive = rgba(444444ff)

        groupbar {
          keep_upper_gap = false

          # give the group bar a background
          # https://github.com/hyprwm/Hyprland/discussions/3284#discussioncomment-13620599
          height = 1
          font_size = 10

          # about half the indicator height
          text_offset = -12
          indicator_height = 24

          col.active = rgba(d7992166)
          col.inactive = rgba(3c383666)
        }
      }

      animations {
        enabled = yes

        bezier = easeOutQuint,0.23,1,0.32,1
        bezier = almostLinear,0.5,0.5,0.75,1.0

        #           NAME,             ONOFF, SPEED, CURVE,        [STYLE]
        # switch workspaces instantly
        animation = workspaces,       0
        animation = specialWorkspace, 1,     1.94,  almostLinear, fade
        animation = windowsIn,        1,     2.0,   easeOutQuint, popin 87%
      }

      misc {
        # be less aggressive about popping up the "application not responding"
        # dialog.
        # default is 5.
        anr_missed_pings = 10
      }

      #############
      ### INPUT ###
      #############

      # https://wiki.hypr.land/Configuring/Variables/#input
      input {
          kb_layout = us,us
          kb_variant = dvorak,
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
##
      # See https://wiki.hypr.land/Configuring/Keywords/
      #$mainMod = SUPER # Sets "Windows" key as main modifier
      $mainMod = ALT

      # Example binds, see https://wiki.hypr.land/Configuring/Binds/ for more
      bind = SHIFT ALT, Return, exec, $terminal
      bind = SHIFT ALT, C, killactive,
      bind = SHIFT ALT, Q, exit,
      #bind = $mainMod, V, togglefloating,
      bind = $mainMod, P, exec, $menu
      #bind = $mainMod, P, pseudo, # dwindle
      bind = $mainMod, v, togglesplit, # dwindle

      bind = $mainMod, F, fullscreenstate, 1 0

      # Move focus with mainMod + arrow keys
      bind = ALT, h, movefocus, l
      bind = ALT, j, movefocus, d
      bind = ALT, k, movefocus, u
      bind = ALT, l, movefocus, r

      # resize the active window
      bind = SUPER CTRL, h, resizeactive, -36 0
      bind = SUPER CTRL, s, resizeactive, 36 0
      bind = SUPER CTRL, n, resizeactive, 0 -24
      bind = SUPER CTRL, t, resizeactive, 0 24

      # Return to previous workspace
      bind = ALT, r, workspace, previous

      # Switch workspace
      bind = $mainMod, T, exec, ${gridselect-workspace}/bin/gridselect-workspace focusworkspaceoncurrentmonitor

      # Send window to workspace
      bind = $mainMod SHIFT, T, exec, ${gridselect-workspace}/bin/gridselect-workspace movetoworkspace

      # Special workspaces
      bind = $mainMod, M, togglespecialworkspace, music

      # Tabbed layout
      bind = $mainMod, G, togglegroup
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

      # Lock the screen
      bind = SUPER CTRL, l, exec, hyprlock

      ##############################
      ### WORKSPACES AND WINDOWS ###
      ##############################

      # See https://wiki.hypr.land/Configuring/Workspace-Rules/ for workspace rules

      ${workspaceRules}
      workspace = special:music, on-created-empty:supersonic, gapsout:50
      workspace = name:notes, on-created-empty:obsidian
      workspace = name:web, gapsout:10 20 10 20

      # See https://wiki.hypr.land/Configuring/Window-Rules/ for more

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

      windowrule = workspace special:music,class:Supersonic

      #debug {
      #  disable_logs = false
      #}
    '';
  };

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

  services.hyprpaper = {
    enable = true;
    settings = {
      preload = [
        "/home/bct/images/wallpaper/View_of_Vent_in_the_Ventertal.jpg"
      ];

      wallpaper = [
        ",/home/bct/images/wallpaper/View_of_Vent_in_the_Ventertal.jpg"
      ];
    };
  };

  gtk = {
    enable = true;
    font = {
      name = "Ubuntu";
      size = 8;
    };
  };
}
