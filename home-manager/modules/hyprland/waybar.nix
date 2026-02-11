{ ... }:
let
  workspaces = import ./workspaces.nix;
in
{
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    settings = [
      {
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
        "hyprland/workspaces" =
          let
            ws-icons = builtins.listToAttrs (
              map (ws: {
                name = ws.name;
                value = ws.icon;
              }) workspaces
            );
          in
          {
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
          format-icons = [
            ""
            ""
            ""
            ""
            ""
            ""
            ""
            ""
            ""
          ];
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
          format-charging = "{capacity}% 󰢝";
          format-plugged = "{capacity}%  ";
          format-alt = "{time} {icon} ";
          format-icons = [
            ""
            ""
            ""
            ""
            ""
          ];
        };
        "network#wireless" = {
          "interface" = "wlp*";
          "format-wifi" = "{signalStrength}% ";
          "format-ethernet" = "{ipaddr}/{cidr} 󰈀";
          "tooltip-format" = "{ifname} via {gwaddr}";
          "format-linked" = "{ifname} (No IP) 󰲊";
          "format-disconnected" = "Disconnected 󰲛";
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
            "default" = [
              ""
              ""
              ""
            ];
          };
          on-click = "pavucontrol";
        };
      }
    ];

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
}
