{
  pkgs,
  config,
  lib,
  ...
}:
{
  programs.regreet = {
    enable = true;
    theme = {
      name = "Gruvbox-Dark";
      package = pkgs.gruvbox-gtk-theme;
    };
    iconTheme = {
      name = "oomox-gruvbox-dark";
      package = pkgs.gruvbox-dark-icons-gtk;
    };

    settings.skip_selection = true;

    # Only show the greeter on the last connected output (e.g. the external
    # monitor), rather than stretching it across all of them.
    cageArgs = [
      "-s"
      "-d"
      "-m"
      "last"
    ];
  };

  # Same as the regreet module's default, but tell cage to use our keyboard layout.
  services.greetd.settings.default_session.command =
    let
      cfg = config.programs.regreet;
      xkb = config.services.xserver.xkb;
    in
    "${pkgs.coreutils}/bin/env XKB_DEFAULT_LAYOUT=${xkb.layout} XKB_DEFAULT_VARIANT=${xkb.variant} ${pkgs.dbus}/bin/dbus-run-session ${lib.getExe pkgs.cage} ${lib.escapeShellArgs cfg.cageArgs} -- ${lib.getExe cfg.package}";
}
