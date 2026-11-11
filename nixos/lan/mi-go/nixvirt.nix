# see yuggoth/README.md for full instructions
#
# to generate UUIDs:
#
#     ruby -r securerandom -e "puts SecureRandom.uuid"
{
  self,
  ...
}:
{
  imports = [ "${self}/nixos/modules/nixvirt" ];

  diffeq.nixvirt = {
    enable = true;
    waitForZfs = true;
    user = "bct";
    guests = {
      ranger = {
        uuid = "5de23a0d-8545-4b6c-ba0c-f3ba3b138e8c";
        address = "192.168.201.20";
        routed = true;
        ipv6 = {
          enable = true;
          # derived from ranger's machine ID, so it's stable but not in this
          # repo. the router's inbound rtorrent rule matches it as a suffix.
          token = "machine-id";
        };
        memoryMB = 2048;
        mounts = [
          {
            source = "/mnt/bulk/video";
            mountPoint = "/mnt/video";
          }

          {
            source = "/mnt/bulk/beets";
            mountPoint = "/mnt/beets";
          }

          {
            source = "/mnt/bulk/media/downloads/pth";
            mountPoint = "/bulk/downloads/pth";
          }

          {
            source = "/mnt/bulk/software/downloads/ggn";
            mountPoint = "/bulk/downloads/ggn";
          }

          {
            source = "/mnt/bulk/media/downloads/mam";
            mountPoint = "/bulk/downloads/mam";
          }
        ];
      };
    };
  };
}
