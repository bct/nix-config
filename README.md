To apply a system configuration:

    sudo nixos-rebuild switch --flake .#hostname

To apply a home configuration:

    home-manager switch --flake .#username@hostname

## Building ARM64 on x86\_64

On Arch, install these packages:

    qemu-system-aarch64 qemu-user-static qemu-user-static-binfmt

On non-NixOS, add these lines to /etc/nix/nix.conf:

    # Allow us to build ARM64 packages using QEMU
    extra-platforms = aarch64-linux

And `systemctl restart nix-daemon`.

On NixOS, add this line to `configuration.nix`:

    boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

Now you can build a VM with your host's config:

    nixos-rebuild build-vm --flake .#hostname

## Building a Raspberry Pi installation image

    nix develop
    nixos-generate -f sd-aarch64-installer --flake .#rpiInstaller

To uncompress the image:

    nix shell nixpkgs#zstd -c unzstd -o <output>.img <input>.img.zst

There's a `compressImage` option that might allow us to avoid this step.

## Installing on a new device

Add bct's SSH public key to git.domus.diffeq.com.

    git clone git@git.domus.diffeq.com:nix-config.git
