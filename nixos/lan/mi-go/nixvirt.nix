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
    user = "bct";
    guests = {
      ranger = {
        uuid = "5de23a0d-8545-4b6c-ba0c-f3ba3b138e8c";
        memoryMB = 2048;
        mounts = [
          {
            source = "/mnt/bulk/video";
            mountPoint = "/mnt/video";
          }

          {
            source = "/mnt/bulk/media/downloads/pth";
            mountPoint = "/bulk/downloads/pth";
          }

          {
            source = "/mnt/bulk/software/downloads/ggn";
            mountPoint = "/bulk/downloads/ggn";
          }
        ];
      };
    };
  };
}
