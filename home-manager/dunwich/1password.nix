{ pkgs, ... }:

{
  config = {
    systemd.user.services."1password" = {
      Unit = {
        Description = "1password";
        PartOf = [ "graphical-session.target" ];
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = "${pkgs._1password-gui}/bin/1password --silent";
        RestartSec = 5;
        Restart = "always";
      };
    };
  };
}
