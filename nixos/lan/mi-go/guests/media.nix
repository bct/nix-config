{
  self,
  config,
  lib,
  ...
}:
let
  jellyfinPort = 8096;
in
{
  imports = [
    "${self}/nixos/modules/lego-proxy-client"
  ];

  system.stateVersion = "25.11";

  microvm = {
    vcpu = 2;
    mem = 2560;

    volumes = [
      {
        image = "var.img";
        mountPoint = "/var";
        size = 8192;
      }
    ];

    shares = [
      {
        tag = "video";
        source = "/mnt/bulk/video";
        mountPoint = "/mnt/video";
        proto = "virtiofs";
      }
    ];
  };

  age.secrets = {
    # a hashed password.
    passwd-blackbeard.rekeyFile = ./secrets/passwd-media-blackbeard.age;
  };

  services.openssh = {
    settings.PasswordAuthentication = lib.mkForce true;
    # TODO: add a chroot here.
    extraConfig = ''
      Match user blackbeard
        ForceCommand internal-sftp
    '';
  };

  users.users.blackbeard = {
    isSystemUser = true;
    group = "blackbeard";
    hashedPasswordFile = config.age.secrets.passwd-blackbeard.path;

    # system users default to nologin.
    # sshd won't let us execute commands without a shell.
    useDefaultShell = true;

    # TODO: prune this list, automate it, limit it to SFTP
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDkP0q1wwfAqQfNH8eBaQI6hNQY8GkBsDYn/8Z8Fe07jVtS5CB38zmJT+iaLPWdYenuZ8YEfNxEeuJJN74JSpx9mBEt771rSRzt2KMIGM7MirJFtqlyZFEigiKrpU429Cw4yl+7Wa2jxjtu7iHXT1URNMDb7bulRoQZ0StBoTC1y2YtQHXAzdvhPnadW5fdvSmWMnBiMUnInaLG32ldJdoEMCYNOMAuatnZqSAUCDQtYzjujmkQw+1bG0BOvGhyKpbU0wSsebOzDbU40biKJ/ydHP+UTcN0ffffbFECUKhKmf2zcvfrUG3gq9N5guJZnijAiYXvj4vLADZExB0b2FP9 root@fever-dreams"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCzJrKWIcrBZetzbd59AK/P5ffBPgQJg+x8ECF5t500f1fGafpcifMhDNWBvTRHssTEIfBf9LqZNcxCbsf18gKQP4cV+8zc7zgv8GvWVPXbPR2t2kZtpcutYLP2X5Lji/xnip9qmXyaPMmoA8Ira2l7kebug0B//YPWDLE8xfar9ssv4Z4XPJ71C9GJiaCmmSQqTadwUYKd8kVXy+UyFRd9f0YLgP+wD4LBgRSokKU1VseNZW+4Cr3Qn0SW/7wZDLTLi9koFWUQzqc0v3XEUhIBhPpanuEDTLOQKC4/zB/vI/tqE6UjUdAmRmPunhpQsmzfP1j1rxoUOAsyyPjQJbXKClydzLBHsyV37d8Dcykl919Wwz89TWzo76k+wJbh/E3/NbBMH/xJ1Cf2tN9+9fyfLzQjzy5a5JUAbY8oh9LKMZAmaYiQq94j3rsC4GGrhLE8F+IPMzC7pE6hH3yjuC7VpwXaAC9xL7xLbdlI8jZOYQrFbDQAsR4bfCUcpT4VQrs= root@theatre"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCzV4OE+rrL8kNlyk76bwtUtoVr+GWbmInZQEPMUg0kyodTeEdjxwMbszPYRuNlzbjA/HfABiqGnQXUdQk8RfLsqXSNtZisaoqawdxOdv0oga9/n99lZrdED2MG37mfjgBFaMoRsXLhhL2cc81HNDbRL2H7ZXFzNfkjBITxdpDcAYMoR9Yu7zdv6fMDQcmUIbzJ5su2M/8yv3ft4gbYh1PzvQOliBPUIAfz67Yv2S7kX7gVkm6ntPeoLmLxvVU0VrI7q+2cuj9tInMFzjYJDPTqlIDoHnitQjqDUFsdAVVqqkWh2cxfELMsco4Qi6tY8+DsjVn4+MFzCjg/XGH5Le1kjQEhvRHQZNypfwJrT0RjcccpywRdJjyWCcn4soogazyLQU/Gkm6BDKJrxYxbLp5CckOzen3pGuY4txgJ9b4cObnhpxLHr7OWw1fERfBRLVeMfX7ZB4h/viM5XxyiKo3VnTAISmTV6RaWmjqA6kr3I9iWzjn2ByPO9ndYgEtSHhU= root@kitchen"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC6cllfw2JApdXcxSXySq9UDFXYGKhvqYrGw+s5FU8MJuxeC6m7qT8Rao2e9xZwTQsNiXiHx8l1F71+bPrVAYQybvabF3YSkaeY5U+tQJpbKUScuc2ySqYCq1CQg9n5X3NmPxOBYqgV8JAABs23GqNkglEJk/9bTkMlakoDB9gmcXrq/g0CTtnbvwdDJBfjbI+cCBD0GvQLL6biHulUJmvrkHa89Xo+42wk7+c+WmesY0KDKyAVQ3l/pk9xI+GTuVV5lSB5YYJKIODOEA80Dq8HjsPXn/yVAWn7T13LVS50XRPO7s8+8YGOvGc+5LUPghW823Ung29tkLzaIprteZB9OKS/34zWgrt1GxXoy3dYuVUwICxZa4oN+xawk50sBe3vmSCqMf4B58mL8Rq1iBEIgoUKI8D144wFSkRVMfss7ILaM4p2qLWUmB5DWvtwKI8eGDzaaK6uZ3kKDEzj4jer03ARgNqHZQca17tL9msVDTGtoQkdJ51Xacp1hq2qBPE= kodi@fever-dreams-nixos"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCljtWAe3ah8XLO7jDLJxUJ2usaEV8ioCKNHN4h3+SmC0aXrjqVDqhFoN3tU7n3GaAjY4vRfzh1i4AKeMOr7e5P4p+tsKTmBjRrffUmad2D74MMiIJVR6jQR9y5QhLHDiZfHYGMxxGKgCGZqxZjRA2YAW0V9WgoY/uZqus0azI547SxRWarHcF9ZQEpzkfdSEpMfhFqOEa0k7U+3ADQH04RAGB+KGqZzQ3TGW6NY8JbQaWnXHKQ7RCu5shzop92cSrEk3ogSui88XXhJdrJQrjPp904sO85v1dADlFFn81+tbXudlKxlfORIXdyKiPZ2ZIwQybwgWoe+dnP0RhgVcol root@fever-dreams (batocera, 2023-04-16)"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEGmTPCC9Vpb2my7QstIIFhsw1/DTDh+3RQR7F9Vp5dt gamer@fever-dreams (nixos+opengamepadui, 2025-04-12)"
    ];
  };
  users.groups.blackbeard = {
    gid = 1005;
    members = [ "blackbeard" ];
  };

  services.lego-proxy-client = {
    enable = true;
    domains = [
      "jellyfin"
      "seerr"
    ];
    group = "caddy";
  };

  services.jellyfin = {
    enable = true;
    openFirewall = false;
  };

  services.jellyseerr = {
    enable = true;
    openFirewall = false;
  };

  services.caddy = {
    enable = true;
    virtualHosts."jellyfin.domus.diffeq.com" = {
      useACMEHost = "jellyfin.domus.diffeq.com";
      extraConfig = "reverse_proxy localhost:${toString jellyfinPort}";
    };
    virtualHosts."seerr.domus.diffeq.com" = {
      useACMEHost = "seerr.domus.diffeq.com";
      extraConfig = "reverse_proxy localhost:${toString config.services.jellyseerr.port}";
    };
  };

  services.netbird.clients.default = {
    port = 51820;
    name = "netbird";
    interface = "wt0";
    hardened = true;
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  networking.firewall.interfaces."wt0".allowedTCPPorts = [
    jellyfinPort
  ];
}
