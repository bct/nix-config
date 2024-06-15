{ ... }: {
  networking.firewall.allowedTCPPorts = [ 80 443 ];

  systemd.tmpfiles.rules = [
    # ensure that /srv/diffeq.com exists.
    # "-" means no automatic cleanup.
    "d /srv/diffeq.com 0755 bct bct -"
  ];

  services.caddy = {
    enable = true;
    virtualHosts."diffeq.com".extraConfig = ''
      root * /srv/diffeq.com

      # I don't have any content at /, so just redirect to my about page
      redir / /bct temporary

      # https://caddy.community/t/how-to-serve-html-files-without-showing-the-html-extension/16766/3
      try_files {path}.html
      encode gzip
      file_server
    '';
  };
}
