{ ... }:

{
  services.borgmatic = {
    enable = true;
    settings = {
      repositories = [
        {
          label = "borg.domus.diffeq.com";
          path = "ssh://borg@borg.domus.diffeq.com/srv/borg/cimmeria/";
        }
      ];

      source_directories = [
        "/home"
      ];

      exclude_patterns = [
        "/home/*/.cache"
        "/home/bct/videos"
      ];

      # TODO: move this into age?
      ssh_command = "ssh -i /root/.ssh/borg";

      # retention
      keep_daily = 14;
      keep_weekly = 8;
      keep_monthly = 12;
      keep_yearly = 1;

      ntfy = {
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

        # List of monitoring states to ping for. Defaults to pinging for failure only.
        states = ["finish" "fail"];
      };
    };
  };

  systemd.services.borgmatic.unitConfig.ConditionACPower = "";
}
