{ pkgs, ... }:
{
  programs.lutris = {
    enable = true;
    defaultWinePackage = pkgs.proton-ge-bin;
    protonPackages = [ pkgs.proton-ge-bin ];
    extraPackages = with pkgs; [
      winetricks
      gamescope
      gamemode
      mangohud
      umu-launcher
    ];
  };
}
