{ pkgs, ... }: {
  imports = [
    ../desktop
    ./1password.nix
  ];

  personal.user = "brendan";
  personal.email = "brendan@artificial.agency";

  personal.xmonad.extraWorkspaces = ./files/ExtraWorkspaces.hs;
  home.file.".xmobarrc".source = ./files/xmobarrc.hs;

  home.pointerCursor = {
    package = pkgs.hackneyed;
    name = "Hackneyed";
    size = 24;
    x11.enable = true;
  };

  home.packages = with pkgs;
    let
      terraform-1_8_5 = pkgs.mkTerraform {
        version = "1.8.5";
        hash = "sha256-5PzP0LUJPpOQQ8YqwBFyEFcsHF2O1uDD8Yh8wB3uJ8s=";
        vendorHash = "sha256-PXA2AWq1IFmnqhhU92S9UaIYTUAAn5lsg3S7h5hBOQE=";
      };
    in [
      slack

      vscode

      python311
      (python312 // { meta.priority = 10; })
      awscli2
      ansible
      process-compose

      terraform-1_8_5

      prismlauncher

      unstable.devenv
    ];

  programs.git.lfs.enable = true;

  # set the urgent flag on Slack when it sends a notification
  # https://gist.github.com/andreycizov/738f80a16c9e401d6a9e77b863e67066
  services.dunst.settings.slack = let
    setUrgent = pkgs.writeShellScript "dunst-set-urgent" ''
      ${pkgs.wmctrl}/bin/wmctrl -r $1 -b add,demands_attention
    '';
  in {
    appname = "Slack";
    summary = "*";

    script = toString setUrgent;
  };

  programs.autorandr = {
    enable = true;
  };

  services.autorandr = {
    enable = false;
  };

  programs.oh-my-posh = {
    enable = true;
    settings = builtins.fromJSON (builtins.unsafeDiscardStringContext (builtins.readFile ./oh-my-posh.json));
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.05";
}
