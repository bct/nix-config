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

    # Delegate X session configuration to home-manager.
    services.xserver.enable = true;
    services.displayManager.defaultSession = "xsession";
    services.xserver.displayManager = {
      # possibly required for greetd/tuigreet?
      startx.enable = true;

      session = [
        {
          manage = "desktop";
          name = "xsession";
          start = ''exec $HOME/.xsession'';
        }
      ];
    };

    services.greetd = {
      enable = true;
      # TODO: once on unstable
      # useTextGreeter = true;
      settings = {
        default_session = {
          command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --remember-session --asterisks";
          user = "greeter";
        };
      };
    };

    fonts = {
      enableDefaultPackages = true;
      packages = [
        pkgs.vista-fonts
      ];
    };

    programs.hyprland = {
      enable = true;

      # Launch Hyprland with the UWSM (Universal Wayland Session Manager)
      # session manager. This has improved systemd support and is recommended
      # for most users.
      # withUWSM = true;
    };

    users.users.${cfgPersonal.user} = {
      isNormalUser = true;
      extraGroups = [ "wheel" "audio" "networkmanager" "video" "lp" "scanner" "dialout" ];
    };

    nix.settings.trusted-users = [ "@wheel" ];

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
