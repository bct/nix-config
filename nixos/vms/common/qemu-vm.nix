{ lib, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  boot.initrd.availableKernelModules = [
    "ahci"
    "xhci_pci"
    "virtio_pci"
    "sr_mod"
    "virtio_blk"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    autoResize = true;
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "systemd-1";
    fsType = "autofs";
  };

  swapDevices = [ ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp1s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # https://github.com/nix-community/nixos-generators/blob/master/formats/qcow.nix
  boot.growPartition = true;
  boot.loader.grub.device = "/dev/vda";
  # show the GRUB menu for a few seconds, so a generation that breaks
  # networking can be skipped from the serial console:
  #   virsh start <guest> --console     (or virsh console <guest> during a reboot)
  boot.loader.timeout = 5;

  # serial console on ttyS0, for `virsh console <guest>` on the host (the
  # domain side is in nixos/modules/nixvirt). GRUB's menu and the kernel's
  # messages go to both the screen and the serial port; listing ttyS0 last
  # makes it the primary console, and systemd starts a getty on it.
  boot.kernelParams = [
    "console=tty0"
    "console=ttyS0,115200"
  ];
  boot.loader.grub.extraConfig = ''
    serial --unit=0 --speed=115200
    terminal_input serial console
    terminal_output serial console
  '';

  # log in as root automatically on the consoles (serial, and the SPICE
  # screen). Only someone with libvirt access on the host can reach them, and
  # that already amounts to root over the guest.
  services.getty.autologinUser = "root";

  # leaving `virsh console` doesn't end the session, so don't leave a root
  # shell sitting open on the console indefinitely.
  programs.bash.interactiveShellInit = ''
    case "$(tty)" in
      /dev/ttyS0|/dev/tty[0-9]*)
        TMOUT=600
        readonly TMOUT
        export TMOUT
        ;;
    esac
  '';
}
