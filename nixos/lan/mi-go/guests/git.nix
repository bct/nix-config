{
  self,
  pkgs,
  config,
  ...
}:
{
  system.stateVersion = "25.11";

  microvm = {
    vcpu = 1;
    mem = 512;

    volumes = [
      {
        image = "var.img";
        mountPoint = "/var";
        size = 1024;
      }
    ];

    shares = [
      {
        tag = "git";
        source = "/mnt/bulk/srv/git";
        mountPoint = "/srv/git";
        proto = "virtiofs";
      }
    ];
  };

  imports = [ "${self}/nixos/modules/borgmatic" ];

  diffeq.borgmatic = {
    enable = true;
    backupName = "git";
    sshKeyPath = config.age.secrets.ssh-borg-git.path;

    settings = {
      source_directories = [ "/srv/git" ];

      # state directories must be on a persistent volume.
      borg_base_directory = "/var/lib/borg";
      borgmatic_source_directory = "/var/lib/borgmatic";
    };
  };

  age.secrets = {
    ssh-borg-git = {
      rekeyFile = config.diffeq.secretsPath + /ssh/borg-git.age;
      generator.script = "ssh-ed25519-pubkey";
    };
  };

  users.users.git = {
    isSystemUser = true;
    uid = 1001; # TODO: make this consistent with the host
    group = "git";
    home = "/srv/git";
    shell = "${pkgs.git}/bin/git-shell";
    openssh.authorizedKeys.keys = [
      # TODO: centralize this list of keys
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHNTfD6cumyn09coFaK0Qf5X/u1fspSLcfN1UytVyuwv bct@aquilonia 2025-10-22"
    ];
  };
  users.groups.git = {
    gid = 1001; # TODO: make this consistent with the host
  };
}
