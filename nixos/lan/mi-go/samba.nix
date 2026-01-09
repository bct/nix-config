{ pkgs, config, ... }:
{
  services.samba = {
    enable = true;
    # The full package is needed to register mDNS records (for discoverability), see discussion in
    # https://gist.github.com/vy-let/a030c1079f09ecae4135aebf1e121ea6
    package = pkgs.samba4Full;
    openFirewall = true;

    settings = {
      global = {
        # TODO: harden.
        "server smb encrypt" = "required";
        "server min protocol" = "SMB3_00";
        "guest ok" = "no";
        "security" = "user";
      };

      photos = {
        path = "/mnt/bulk/home/photos";
        browseable = "no";
        "read only" = "no";
      };

      paperless = {
        path = "/mnt/bulk/home/paperless";
        browseable = "no";
        "read only" = "no";
      };
    };
  };

  # set samba user passwords.
  system.activationScripts = {
    # The "init_smbpasswd" script name is arbitrary, but a useful label for tracking
    # failed scripts in the build output. An absolute path to smbpasswd is necessary
    # as it is not in $PATH in the activation script's environment. The password
    # is repeated twice with newline characters as smbpasswd requires a password
    # confirmation even in non-interactive mode where input is piped in through stdin.
    init_smbpasswd_immich.text = ''
      ${pkgs.coreutils}/bin/printf "$(${pkgs.coreutils}/bin/cat ${config.age.secrets.passwd-immich.path})\n$(${pkgs.coreutils}/bin/cat ${config.age.secrets.passwd-immich.path})\n" | ${config.services.samba.package}/bin/smbpasswd -sa immich
    '';
    init_smbpasswd_paperless.text = ''
      ${pkgs.coreutils}/bin/printf "$(${pkgs.coreutils}/bin/cat ${config.age.secrets.passwd-paperless.path})\n$(${pkgs.coreutils}/bin/cat ${config.age.secrets.passwd-paperless.path})\n" | ${config.services.samba.package}/bin/smbpasswd -sa paperless
    '';
  };

  age.secrets = {
    passwd-immich.rekeyFile = ./secrets/passwd-immich.age;
    passwd-paperless.rekeyFile = ./secrets/passwd-paperless.age;
  };
}
