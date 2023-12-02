{ lib, config, pkgs, ... }:

let cfgPersonal = config.personal;
in {
  options = {
    personal.xmonad = {
      extraWorkspaces = lib.mkOption {
        type = lib.types.path;
      };
    };
  };

  config = {
    xsession.windowManager = {
      xmonad = {
        enable = true;
        enableContribAndExtras = true;
        config = ./files/xmonad.hs;
        libFiles = {
          "Workspaces.hs" = ./files/Workspaces.hs;
          "ExtraWorkspaces.hs" = cfgPersonal.xmonad.extraWorkspaces;
        };
      };
    };

    home.packages = with pkgs; [
      xmobar

      (nerdfonts.override { fonts = [ "UbuntuMono" ]; })
      ubuntu_font_family

      alacritty
      dmenu
      light
    ];
  };
}
