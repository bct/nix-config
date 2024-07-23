{ config, pkgs, lib, ... }:

let cfgPersonal = config.personal;
in {
  imports = [
    ./packages.nix
  ];

  options = {
    personal = {
      user = lib.mkOption {
        type = lib.types.str;
        description = "Username for the primary user.";
      };
    };
  };

  config = {
    boot.kernel.sysctl = {
      # work around my network's weird MTU issues
      "net.ipv4.tcp_mtu_probing" = 1;
    };

    networking.networkmanager.enable = true;

    time.timeZone = "America/Edmonton";

    i18n.defaultLocale = "en_CA.UTF-8";
    console.keyMap = "dvorak";

    services.xserver.xkb = {
      layout = "us";
      variant = "dvorak";
    };

    environment.variables.EDITOR = "vim";

    # Delete old generations to save space.
    nix.gc = {
      automatic = true;
      options = "--delete-older-than 7d";
    };

    # Enable CUPS.
    services.printing.enable = true;

    # Enable printer discovery.
    services.avahi.enable = true;
    services.avahi.nssmdns4 = true;

    # Enable scanner
    hardware.sane = {
      enable = true;
      extraBackends = [ pkgs.sane-airscan ];
    };

    sound.enable = true;

    # Enable X and lightdm.
    # Delegate X session configuration to home-manager.
    services.xserver.enable = true;
    services.displayManager.defaultSession = "default";
    services.xserver.displayManager = {
      lightdm = {
        enable = true;
        greeters.slick = {
          enable = true;
          theme.name = "Adwaita-dark";
        };
      };

      session = [
        {
          manage = "desktop";
          name = "default";
          start = ''exec $HOME/.xsession'';
        }
      ];
    };

    users.users.${cfgPersonal.user} = {
      isNormalUser = true;
      extraGroups = [ "wheel" "audio" "networkmanager" "video" "lp" "scanner" ];
    };

    # Allow users to mount removeable storage.
    services.devmon.enable = true;
    programs.udevil.enable = true;

    security.sudo = {
      enable = true;
      execWheelOnly = true;
      extraConfig = ''
        # share sudo session across terminal sessions
        Defaults timestamp_type=global
        Defaults insults
      '';
    };

    # use emulation to compile aarch64 packages
    boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
  };
}
