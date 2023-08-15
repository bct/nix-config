{ pkgs, ... }:

{
  boot.kernel.sysctl = {
    # work around my network's weird MTU issues
    "net.ipv4.tcp_mtu_probing" = 1;
  };

  networking.networkmanager.enable = true;

  time.timeZone = "America/Edmonton";

  i18n.defaultLocale = "en_CA.UTF-8";
  console.keyMap = "dvorak";
  services.xserver.layout = "dvorak";

  environment.variables.EDITOR = "vim";

  # Enable CUPS.
  services.printing.enable = true;

  # Enable printer discovery.
  services.avahi.enable = true;
  services.avahi.nssmdns = true;

  sound.enable = true;

  # Enable X and lightdm.
  # Delegate X session configuration to home-manager.
  services.xserver.enable = true;
  services.xserver.displayManager.defaultSession = "default";
  services.xserver.displayManager.session = [
    {
      manage = "desktop";
      name = "default";
      start = ''exec $HOME/.xsession'';
    }
  ];

  # Get AppImages (cura) working.
  # "For the sandboxed apps to work correctly, desktop integration portals need to be installed."
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.bct = {
    isNormalUser = true;
    extraGroups = [ "wheel" "audio" "networkmanager" "video" ];
    packages = with pkgs; [
      chromium
      brave
      mpv
      epdfview
      libreoffice

      cura5
      freecad

      ansible
      nmap

      # for "strings"
      binutils
    ];
  };

  environment.systemPackages = with pkgs; [
    vim
    git
    wget

    home-manager

    sshfs
    exfat
    ntfs3g

    # killall, etc.
    psmisc
  ];

  # Allow users to mount removeable storage.
  services.devmon.enable = true;
  programs.udevil.enable = true;

  # use emulation to compile aarch64 packages
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
}
