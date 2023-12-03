{ ... }:

{
  services.dunst = {
    enable = true;

    settings = {
      global = {
        font = "UbuntuMono Nerd Font 18";
        frame_color = "#83a598";

        origin = "bottom-right";
        offset = "10x10";
      };

      urgency_low = {
        background = "#282828";
        foreground = "#ebdbb2";
      };

      urgency_normal = {
        background = "#83a598";
        foreground = "#282828";
      };

      urgency_critical = {
        background = "#fabd2f";
        foreground = "#282828";
      };
    };
  };
}
