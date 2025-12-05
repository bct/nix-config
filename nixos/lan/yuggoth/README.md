## Bootstrapping a libvirt VM

    nix build .#headless-image-cloud-x86_64-qcow2
    scp result/nixos.qcow2 yuggoth:

    # on yuggoth, as root
    DEST=/srv/libvirt/images/xxx-root.qcow2
    DISK_SIZE=20G

    # set up the qcow image
    mv ~bct/nixos.qcow2 $DEST
    chown qemu-libvirtd:qemu-libvirtd $DEST
    chmod 0600 $DEST
    virsh pool-refresh default

    # resize the disk.
    # possibly you could use "virsh vol-resize" here?
    qemu-img resize $DEST $DISK_SIZE

    # start your VM.
    # now you should be able to deploy to it.
