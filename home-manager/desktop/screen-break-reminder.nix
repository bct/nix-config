{ pkgs, ... }:

{
  systemd.user.services = {
    screen-break = {
      Unit = {
        Description = "screen break reminder service";
      };
      Service = {
        Type = "oneshot";
        ExecStart = toString (
         pkgs.writeShellScript "screen-break-script" ''
           ${pkgs.dunst}/bin/dunstify -u low "screen break"
         ''
        );
      };
      Install.WantedBy = [ "default.target" ];
    };
  };

  systemd.user.timers = {
    screen-break = {
      Unit.Description = "remember to look away from your screen every 15m";
      Timer = {
        Unit = "screen-break";
        OnUnitActiveSec = "15m";
      };
      Install.WantedBy = [ "timers.target" ];
    };
  };
}
