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
      auth = {
        uuid = "277ae744-e184-46ec-bdfd-93992fa4241b";
        memoryMB = 1024;
      };
      mail = {
        uuid = "6bdbad6f-540c-4114-a063-16fec1995347";
        memoryMB = 1024;
        disks = [
          {
            device = "/dev/mapper/fastpool-mail--var";
            target = "vdb";
          }
        ];
      };
      medley = {
        uuid = "76a25495-6730-4982-9761-637f57f18e4a";
        memoryMB = 3072;
      };
    };
  };
}
