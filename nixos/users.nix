{ inputs, lib, config, pkgs, ... }: {
   users.users = {
    bct = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDAu6kY7KruzDByDYDx3k8NYe3pMxROrRxxb4rWVNfxfx5pu4Gp/fncXhK4kymxer8xbyOWBLnigHcFbdlgoIhVL7SgKGfziIrfN+cYMflKCyY5OznfPBJSD2OHiMPpQ4a/SIDrl/P6N+SqVebku4ay7N8aL62dD3xquTM5nw+3FysXsy5d1Wv/p3zt3lR3zxKYoC6gPaxUEuX7c1MRO+8VtFPge9f/Pmi2oWSjx8dKspeU83Ur/HwZfZdUSN8ABWAsV80DCI15LjlM81oyehQJBdl4AMTCApNioPPtZexYkf0UwGXh9PhMfP9cKC/dUbAfbh2eS/ReteC81G1MPPf9C3AzxDBh/k4iIarTU6pTgumSaV5rSvYxtjpxaRP4cbRKgNPu8n6XMrUM9cRL+ozBXBmqYWzuzY2QATmVadKZddx3SSoiAtakMLvASGh5RW/hDxm6td49jF4U7XB9sC3dAkRkJFSf91PYeiBgJXzNvsxGlwpJFMmv5vmDPN+HZTU= bct@cimmeria 2022-09-02"
      ];
    };
  };
}
