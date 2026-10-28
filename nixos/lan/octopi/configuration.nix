{
  inputs,
  self,
  pkgs,
  modulesPath,
  config,
  ...
}:
{
  imports = [
    "${self}/nixos/common/agenix-rekey.nix"

    "${self}/nixos/common/nix.nix"
    "${self}/nixos/common/headless.nix"
    "${self}/nixos/common/node-exporter.nix"

    inputs.nixos-raspberrypi.nixosModules.raspberry-pi-3.base

    # defines the filesystems, and lets us build an SD card image with:
    #   nix build .#nixosConfigurations.stereo.config.system.build.sdImage
    inputs.nixos-raspberrypi.nixosModules.sd-image

    ./klipper.nix
  ];

  # the sd-image module imports this installer profile, which adds rescue tools and enables ZFS
  # (which doesn't support the vendor kernel).
  disabledModules = [ (modulesPath + "/profiles/base.nix") ];

  # the firmware boots the kernel directly (no u-boot). generations are kept on the
  # FIRMWARE partition; to boot an older one, edit `os_prefix` in config.txt.
  boot.loader.raspberry-pi.bootloader = "kernel";

  powerManagement.cpuFreqGovernor = "ondemand";

  networking.hostName = "octopi";
  networking.useNetworkd = true;

  networking.wireless = {
    enable = true;
    interfaces = [ "wlan0" ];
    # keep the config encrypted for a little privacy
    extraConfigFiles = [
      config.age.secrets.wifi.path
    ];
  };

  age.secrets = {
    wifi = {
      rekeyFile = config.diffeq.secretsPath + /wpa_supplicant-networks.age;
      owner = "wpa_supplicant";
    };
  };

  # avoid writing logs to disk, try to save the SD card
  services.journald.extraConfig = ''
    Storage=volatile
  '';

  time.timeZone = "America/Edmonton";

  environment.systemPackages = with pkgs; [
    libraspberrypi
    cifs-utils
  ];

  hardware.enableRedistributableFirmware = true;

  age.rekey.hostPubkey = config.diffeq.secretsPath + /ssh/host-octopi.pub;

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "26.05";
}
