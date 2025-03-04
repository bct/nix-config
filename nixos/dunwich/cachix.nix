{
  nix = {
    settings = {
      # a binary cache for unfree packages.
      # without this it takes _forever_ to build mongodb.
      # https://app.cachix.org/cache/nix-community
      # https://nix-community.org/package-sets/
      substituters        = [ "https://nix-community.cachix.org" ];
      trusted-public-keys = [ "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" ];
    };
  };
}
