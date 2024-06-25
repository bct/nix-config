let
  # user keys
  bct-cimmeria = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDAu6kY7KruzDByDYDx3k8NYe3pMxROrRxxb4rWVNfxfx5pu4Gp/fncXhK4kymxer8xbyOWBLnigHcFbdlgoIhVL7SgKGfziIrfN+cYMflKCyY5OznfPBJSD2OHiMPpQ4a/SIDrl/P6N+SqVebku4ay7N8aL62dD3xquTM5nw+3FysXsy5d1Wv/p3zt3lR3zxKYoC6gPaxUEuX7c1MRO+8VtFPge9f/Pmi2oWSjx8dKspeU83Ur/HwZfZdUSN8ABWAsV80DCI15LjlM81oyehQJBdl4AMTCApNioPPtZexYkf0UwGXh9PhMfP9cKC/dUbAfbh2eS/ReteC81G1MPPf9C3AzxDBh/k4iIarTU6pTgumSaV5rSvYxtjpxaRP4cbRKgNPu8n6XMrUM9cRL+ozBXBmqYWzuzY2QATmVadKZddx3SSoiAtakMLvASGh5RW/hDxm6td49jF4U7XB9sC3dAkRkJFSf91PYeiBgJXzNvsxGlwpJFMmv5vmDPN+HZTU=";

  # host keys
  #   ssh-keyscan -t ssh-ed25519 <host>

  # -- lan
  spectator = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHwG+kqbUaFI2xwHZO76CrQh5+YnElQsjB6DOWNtMc1e";
  stereo = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF+0o3CDs78/NW73QxiZ4gJtXgZ5U+NAu8o9lNhzmLwl";
  yuurei = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINqIJgMjI1OWLvn6eOrlsF0TG8jFu6SYkzq85VODtUbP";

  # -- cloud
  megahost-one = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJAbD0X8eQfKiG2rYYcZ6dVdRHQaRK8DrFz7YaLzHQx2";
  s3-proxy = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG/edQPh5lgflnMjVHAHhRDNNmmusQxm7MHU2QE7kiyV";
  notes = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKgWQElHPbvswEcaYNUAQ1E8Kw/KL4e3H4VrGicBNxAJ";
  viator = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHEtc5zAnIK1S6p+8L/FNjYgujVqhGUUG4Y9WpYb06mO";

in
  {
    # mysql password
    "home-assistant-my-cnf.age".publicKeys = [ bct-cimmeria spectator ];

    # influxdb password
    "rtlamr-collect-env.age".publicKeys = [ bct-cimmeria spectator ];

    # admin username/password for minio
    "s3-proxy-minio-root-credentials.age".publicKeys = [ bct-cimmeria s3-proxy megahost-one ];

    # wireguard keys
    "notes-wireguard-key.age".publicKeys = [ bct-cimmeria notes ];
    "viator-wireguard-key.age".publicKeys = [ bct-cimmeria viator megahost-one ];
    "wg/megahost-one-conductum.age".publicKeys = [ bct-cimmeria megahost-one ];

    # SSH keys for accessing borg.domus.diffeq.com
    "notes-borg-ssh-key.age".publicKeys = [ bct-cimmeria notes ];
    "ssh/megahost-one-borg.age".publicKeys = [ bct-cimmeria megahost-one ];

    # ZoneEdit API key for creating TXT records for ACME
    "zoneedit.age".publicKeys = [ bct-cimmeria spectator stereo yuurei ];

    # Nitter OAuth tokens
    "nitter-guest-accounts.age".publicKeys = [ bct-cimmeria yuurei ];

    # Miniflux admin credentials
    "miniflux-admin-credentials.age".publicKeys = [ bct-cimmeria yuurei ];

    # Database passwords
    "db/password-megahost-postgres.age".publicKeys = [ bct-cimmeria megahost-one ];
    "db/password-goatcounter.age".publicKeys = [ bct-cimmeria megahost-one ];
  }
