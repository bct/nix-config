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
        mac = "52:54:00:ac:e3:1f";
        address = "192.168.200.30";
        memoryMB = 1024;
      };
      mail = {
        uuid = "6bdbad6f-540c-4114-a063-16fec1995347";
        mac = "52:54:00:f6:82:fc";
        address = "192.168.200.31";
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
        mac = "52:54:00:46:dd:16";
        address = "192.168.200.32";
        memoryMB = 6144;
      };
    };
  };
}
