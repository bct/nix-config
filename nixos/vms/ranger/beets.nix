{ ... }:
{
  home-manager.users.bct = {
    imports = [
      ../../../home-manager/modules/beets
    ];
  };
}
