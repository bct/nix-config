{
  pkgs,
  config,
  lib,
  ...
}:
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
        #"server smb encrypt" = "required"; # not compatible with guest access?
        "server min protocol" = "SMB3_00";
        "map to guest" = "Bad User";
        "guest account" = "nobody";
        "invalid users" = [ "root" ];
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

      video = {
        path = "/mnt/bulk/video";
        browseable = "no";
        "read only" = "no";
      };

      beets = {
        path = "/mnt/bulk/beets/library";
        browseable = "yes";
        "read only" = "yes";
        "guest ok" = "yes";
      };

      software = {
        path = "/mnt/bulk/software";
        browseable = "yes";
        "read only" = "yes";
        "guest ok" = "yes";
      };

      time-machine-amanda-2020-12 = {
        path = "/mnt/bulk/backups/time-machine-amanda-2020-12";
        "valid users" = "amanda";
        public = "no";
        writeable = "yes";
        "fruit:aapl" = "yes";
        "fruit:time machine" = "yes";
        "vfs objects" = "catia fruit streams_xattr";
      };
    };
  };

  # Ensure Time Machine can discover the share without `tmutil`
  services.avahi = {
    enable = true;
    openFirewall = true;
    publish.enable = true;
    publish.userServices = true;
    nssmdns4 = true;
    extraServiceFiles = {
      timemachine = ''
        <?xml version="1.0" standalone='no'?>
        <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
        <service-group>
          <name replace-wildcards="yes">%h</name>
          <service>
            <type>_smb._tcp</type>
            <port>445</port>
          </service>
          <service>
            <type>_device-info._tcp</type>
            <port>0</port>
            <txt-record>model=TimeCapsule8,119</txt-record>
          </service>
          <service>
            <type>_adisk._tcp</type>
            <!-- 
              change tm_share to share name, if you changed it. 
            --> 
            <txt-record>dk0=adVN=time-machine-amanda-2020-12,adVF=0x82</txt-record>
            <txt-record>sys=waMa=0,adVF=0x100</txt-record>
          </service>
        </service-group>
      '';
    };
  };

  # set samba user passwords.
  system.activationScripts =
    let
      sambaPasswordPaths = {
        amanda = config.age.secrets.passwd-amanda.path;
        immich = config.age.secrets.passwd-immich.path;
        paperless = config.age.secrets.passwd-paperless.path;
        torrent-scraper = config.age.secrets.passwd-torrent-scraper.path;
      };
      # The "init_smbpasswd" script name is arbitrary, but a useful label for tracking
      # failed scripts in the build output. An absolute path to smbpasswd is necessary
      # as it is not in $PATH in the activation script's environment. The password
      # is repeated twice with newline characters as smbpasswd requires a password
      # confirmation even in non-interactive mode where input is piped in through stdin.
    in
    lib.mapAttrs' (
      username: path:
      lib.nameValuePair "init_smbpasswd_${username}" {
        text = ''
          ${pkgs.coreutils}/bin/printf "$(${pkgs.coreutils}/bin/cat ${path})\n$(${pkgs.coreutils}/bin/cat ${path})\n" | ${config.services.samba.package}/bin/smbpasswd -sa ${username}
        '';
      }
    ) sambaPasswordPaths;

  age.secrets = {
    passwd-amanda.rekeyFile = ./secrets/passwd-amanda.age;
    passwd-immich.rekeyFile = ./secrets/passwd-immich.age;
    passwd-paperless.rekeyFile = ./secrets/passwd-paperless.age;
    passwd-torrent-scraper.rekeyFile = ./secrets/passwd-torrent-scraper.age;
  };
}
