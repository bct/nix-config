{ inputs, lib, config, pkgs, ... }: {
  services.home-assistant = {
    enable = true;

    # https://github.com/NixOS/nixpkgs/blob/master/pkgs/servers/home-assistant/component-packages.nix
    extraComponents = [
      "default_config"
      "met"
      "mqtt"

      "octoprint"
      "kodi"

      # Zigbee
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

  services.mosquitto = {
    enable = true;
  };

  environment.systemPackages = with pkgs; [
    rtl-sdr
  ];
}
