To apply a system configuration:

    sudo nixos-rebuild switch --flake .#hostname

To apply a home configuration:

    home-manager switch --flake .#username@hostname

To build a package in ./pkgs:

    nix build .#package-name

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

    nix build .#headless-image-rpi

To uncompress the image:

    nix shell nixpkgs#zstd -c unzstd -o <output>.img <input>.img.zst

There's a `compressImage` option that might allow us to avoid this step.

## Building an ISO

    nix build .#headless-image-cloud-x86_64-iso

## Installing on a new Raspberry Pi

SSH in as bct.

    ssh-keygen

Add bct's SSH public key to git.domus.diffeq.com.

    git clone git@git.domus.diffeq.com:nix-config.git

    cd nix-config

    sudo nixos-rebuild switch --flake .#<target>

## Installing on a VPS

Boot from the ISO.

Partition and mount the disk as described in the manual.

Create and mount a swapfile if you want.

rsync nix-config to the host

    sudo nixos-install --no-root-passwd --flake .#<target>

## deploy-rs

    nix run github:serokell/deploy-rs .#<target>
