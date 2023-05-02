To apply a system configuration:

    sudo nixos-rebuild switch --flake .#hostname

To apply a home configuration:

    home-manager switch --flake .#username@hostname
