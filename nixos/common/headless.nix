# Enable SSH with public key authentication.
# Set up a user who can log in via SSH.
{ inputs, pkgs, ... }: {
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  # Preserve space by sacrificing history
  nix.gc.automatic = true;
  nix.gc.options = "--delete-older-than 30d";
  boot.tmp.cleanOnBoot = true;

  # allow users in group "wheel" to deploy using deploy-rs
  nix.settings.trusted-users = [ "@wheel" ];

  # install a base set of packages
  environment.systemPackages = with pkgs; [
    vim
    git
    tmux
  ];

  # don't install nano and perl
  environment.defaultPackages = [ pkgs.rsync pkgs.strace ];

  environment.variables.EDITOR = "vim";

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  users = {
    # do not allow /etc/passwd & /etc/group to be modified directly.
    mutableUsers = false;

    groups = {
      bct = { };
    };

    users = {
      bct = {
        isNormalUser = true;
        group = "bct";
        extraGroups = [ "wheel" ];
        openssh.authorizedKeys.keys = [
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDAu6kY7KruzDByDYDx3k8NYe3pMxROrRxxb4rWVNfxfx5pu4Gp/fncXhK4kymxer8xbyOWBLnigHcFbdlgoIhVL7SgKGfziIrfN+cYMflKCyY5OznfPBJSD2OHiMPpQ4a/SIDrl/P6N+SqVebku4ay7N8aL62dD3xquTM5nw+3FysXsy5d1Wv/p3zt3lR3zxKYoC6gPaxUEuX7c1MRO+8VtFPge9f/Pmi2oWSjx8dKspeU83Ur/HwZfZdUSN8ABWAsV80DCI15LjlM81oyehQJBdl4AMTCApNioPPtZexYkf0UwGXh9PhMfP9cKC/dUbAfbh2eS/ReteC81G1MPPf9C3AzxDBh/k4iIarTU6pTgumSaV5rSvYxtjpxaRP4cbRKgNPu8n6XMrUM9cRL+ozBXBmqYWzuzY2QATmVadKZddx3SSoiAtakMLvASGh5RW/hDxm6td49jF4U7XB9sC3dAkRkJFSf91PYeiBgJXzNvsxGlwpJFMmv5vmDPN+HZTU= bct@cimmeria 2022-09-02"
        ];
      };
    };
  };

  security.sudo.wheelNeedsPassword = false;

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users = {
      bct = import ../../home-manager/base;
    };
  };
}
