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

A generic installer:

    nix build .#headless-image-rpi

Or a specific host:

    nix build .#nixosConfigurations.stereo.config.system.build.sdImage

To uncompress the image:

Flash this image to an SD card:

    zstdcat result/sd-image/nixos-image-rpi3-kernel.img.zst | sudo dd of=/dev/sdX bs=4M status=progress conv=fsync

Boot it and use `deploy-rs` to deploy your configuration.

## Building an ISO

    nix build .#headless-image-cloud-x86_64-iso

## Installing on a VPS

Boot from the ISO.

Partition and mount the disk as described in the manual.

Create and mount a swapfile if you want.

rsync nix-config to the host

    sudo nixos-install --no-root-passwd --flake .#<target>

## deploy-rs

    nix run github:serokell/deploy-rs .#<target>

## LAN DNS (router CNAMEs and hostnames)

The CNAMEs and hostnames on the OpenWrt router are generated from this repo
(`generators/router-dns.nix`). Each machine gets a CNAME for every name in its
`services.lego-proxy-client.domains` and `diffeq.dnsAliases`. Routed VM guests
(`routed = true`, see `nixos/modules/guest-network`) get a hostname with their
static address; everything else is named by its DHCP lease. Any CNAME or
hostname not generated here gets deleted, so make DNS changes in Nix, not in
LuCI.

Stage the changes on the router and review the diff it prints:

    ssh root@router sh < "$(nix build --no-link --print-out-paths .#router-dns)"

Then apply or discard them:

    ssh root@router 'uci commit dhcp && /etc/init.d/dnsmasq reload'
    ssh root@router 'uci revert dhcp'

## lego-proxy secrets

Each name in a machine's `services.lego-proxy-client.domains` has an SSH key in
`secrets/lego-proxy/`: `<name>.age` (private key) and `<name>.pub` (public key;
every `.pub` there is whitelisted on the lego-proxy). To find files no machine
uses, and used names that are missing a file:

    nix run .#lego-proxy-orphans

It only reports; delete orphans yourself with `git rm`, then redeploy the
lego-proxy microvm so it drops them from its whitelist.
