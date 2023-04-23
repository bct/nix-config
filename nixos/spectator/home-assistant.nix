{ inputs, lib, config, pkgs, ... }: {
  services.home-assistant = {
    enable = true;

    extraComponents = [
      # Components required to complete the onboarding
      "met"
      "radio_browser"

      "octoprint"
      "kodi"
      "zha"

      # Printer
      "syncthru"
      "ipp"
    ];

    config = {
      # Includes dependencies for a basic setup
      # https://www.home-assistant.io/integrations/default_config/
      default_config = {};
    };
  };
}
