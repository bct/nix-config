## Bootstrapping a libvirt VM

    nix build .#headless-image-cloud-x86_64-qcow2
    scp result/nixos.qcow2 yuggoth:

    # on yuggoth, as root
    VOL=xxx-root.qcow2
    DEST=/srv/libvirt/images/$VOL
    DISK_SIZE=20G

    # set up the qcow image
    mv ~bct/nixos.qcow2 $DEST
    chown qemu-libvirtd:qemu-libvirtd $DEST
    chmod 0600 $DEST
    virsh pool-refresh default

    # resize the disk.
    virsh vol-resize $VOL 20G default

    # start your VM.
    virsh start

    # now you should be able to deploy to it.
