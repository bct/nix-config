{ ... }:

{
  services.borgmatic = {
    enable = true;
    settings = {
      location.source_directories = [
        "/home"
      ];

      location.repositories = [
        "ssh://borg@borg.domus.diffeq.com/srv/borg/cimmeria/"
      ];

      location.exclude_patterns = [
        "/home/*/.cache"
        "/home/bct/videos"
      ];

      # TODO: move this into age?
      storage.ssh_command = "ssh -i /root/.ssh/borg";

      retention = {
        keep_daily = 14;
        keep_weekly = 8;
        keep_monthly = 12;
        keep_yearly = 1;
      };

      hooks.ntfy = {
        topic = "doog4maechoh";
        finish = {
          title = "[cimmeria] borgmatic finished";
          message = "Your backup has finished.";
          priority = "default";
          tags = "kissing_heart,borgmatic";
        };
        fail = {
          title = "[cimmeria] borgmatic failed";
          message = "Your backup has failed.";
          priority = "default";
          tags = "sweat,borgmatic";
        };

        # List of monitoring states to ping fore. Defaults to pinging for failure only.
        states = ["finish" "fail"];
      };
    };
  };

  systemd.services.borgmatic.unitConfig.ConditionACPower = "";
}
