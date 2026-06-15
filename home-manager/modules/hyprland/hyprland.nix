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
      action=$1

      # open the grid select to choose a workspace.
      workspace_id=$(grid-select -d , <${workspaceSelectors})

      # was a workspace selected?
      if [ -n "$workspace_id" ]; then
        if [ "$action" = "move" ]; then
          # switch to the selected workspace.
          hyprctl dispatch "hl.dsp.window.move({ workspace = \"$workspace_id\" })"
        else
          # switch to the selected workspace.
          hyprctl dispatch "hl.dsp.focus({ workspace = \"$workspace_id\", on_current_monitor = true })"
        fi
      fi
    '';
  };
in

{
  home.packages = [
    gridselect-workspace
  ];

  wayland.windowManager.hyprland = {
    enable = true; # enable Hyprland

    package = pkgs.unstable.hyprland;
    portalPackage = pkgs.unstable.xdg-desktop-portal-hyprland;

    # If you use the Home Manager module, make sure to disable the systemd integration, as it
    # conflicts with uwsm.
    # https://wiki.hypr.land/Useful-Utilities/Systemd-start/
    #systemd.enable = false;

    # settings.env = [
    #   "XCURSOR_THEME,capitaine-cursors"
    #   "XCURSOR_SIZE,18"
    # ];

    configType = "lua";

    # TODO: use extraLuaFiles once that's available
    extraConfig = ''
      local hm_xdg_config_home = os.getenv("XDG_CONFIG_HOME")
      require("00-workspaces")
    ''
    + builtins.readFile ./hyprland.lua;
  };

  xdg.configFile."hypr/00-workspaces.lua".text = lib.concatLines (
    lib.imap1 (
      i: ws: "hl.workspace_rule({ workspace = \"${toString i}\", default_name = \"${ws.name}\" })"
    ) workspaces
  );

}
