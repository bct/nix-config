{ self, ... }:

{
  imports = [
    "${self}/nixos/common/agenix-rekey.nix"
    "${self}/nixos/modules/lego-proxy-client"

    ./spectator/home-assistant.nix
    ./spectator/rtlamr.nix
  ];

  system.stateVersion = "24.05";

  microvm = {
    vcpu = 1;
    mem = 768;

    volumes = [
      {
        image = "var.img";
        mountPoint = "/var";
        size = 2048;
      }
    ];

    # to get vendor and product ID:
    #   nix shell nixpkgs#usbutils -c lsusb
    devices = [
      # RTL2838UHIDIR
      # Realtek Semiconductor Corp. RTL2838 DVB-T
      { bus = "usb"; path = "vendorid=0x0bda,productid=0x2838"; }
      # Sonoff Zigbee 3.0 USB Dongle Plus
      # Silicon Labs CP210x UART Bridge
      { bus = "usb"; path = "vendorid=0x10c4,productid=0xea60"; }
    ];
  };
}
