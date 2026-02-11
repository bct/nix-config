{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
let
  workspaces = import ./workspaces.nix;

  # prepare a list of workspaces for grid-select -d.
  # format: "value,display"
  workspaceSelectors = pkgs.writeText "hyprland-workspaces-selectors" (
    lib.concatImapStrings (wsId: ws: "${toString wsId},${ws.icon}  ${ws.name}" + "\n") workspaces
  );

  gridselect-workspace = pkgs.writeShellApplication {
    name = "gridselect-workspace";
    runtimeInputs = [
      config.wayland.windowManager.hyprland.package
      inputs.grid-select.packages.${pkgs.stdenv.hostPlatform.system}.default
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
in

{
  wayland.windowManager.hyprland = {
    enable = true; # enable Hyprland

    package = pkgs.unstable.hyprland;
    portalPackage = pkgs.unstable.xdg-desktop-portal-hyprland;

    # If you use the Home Manager module, make sure to disable the systemd integration, as it
    # conflicts with uwsm.
    # https://wiki.hypr.land/Useful-Utilities/Systemd-start/
    #systemd.enable = false;

    settings.env = [
      "XCURSOR_THEME,capitaine-cursors"
      "XCURSOR_SIZE,18"
    ];

    # https://github.com/hyprwm/Hyprland/blob/main/example/hyprland.conf
    extraConfig =
      let
        # we could use named workspaces, but this allows us to specify the order
        workspaceRules = lib.concatLines (
          lib.imap1 (i: ws: "workspace = ${toString i}, defaultName:${ws.name}") workspaces
        );
      in
      ''
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
        $menu = fuzzel


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

        ecosystem {
          no_update_news = true
          no_donation_nag = true
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

        # switch monitor focus
        bind = ALT, o, focusmonitor, 0
        bind = ALT, e, focusmonitor, 1

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

        windowrule {
          # Ignore maximize requests from apps. You'll probably like this.
          name = suppress-maximize-events
          match:class = .*

          suppress_event = maximize
        }

        windowrule {
            # Fix some dragging issues with XWayland
            name = fix-xwayland-drags
            match:class = ^$
            match:title = ^$
            match:xwayland = true
            match:float = true
            match:fullscreen = false
            match:pin = false

            no_focus = true
        }

        # Chrome on workspace 2 gets grouped
        windowrule = match:class ^(chromium-browser)$, match:workspace 2, group set

        # Jellyfin opens on workspace 6
        #windowrule = workspace 6 silent,class:^(chromium-browser)$,title:^(Jellyfin)$

        windowrule = match:class Supersonic, workspace special:music

        #debug {
        #  disable_logs = false
        #}
      '';
  };
}
