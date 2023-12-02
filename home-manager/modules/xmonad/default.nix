{ pkgs, ... }:
{
  xsession.windowManager = {
    xmonad = {
      enable = true;
      enableContribAndExtras = true;
      config = ./files/xmonad.hs;
      libFiles = {
        "Workspaces.hs" = ./files/Workspaces.hs;
        "ExtraWorkspaces.hs" = ./files/ExtraWorkspaces.hs;
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
}
