{ config, ... }:
{
  system.stateVersion = "25.11";

  microvm = {
    vcpu = 1;
    mem = 512;

    shares = [
      {
        tag = "borg";
        source = "/mnt/bulk/backups/borg";
        mountPoint = "/srv/borg";
        proto = "virtiofs";
      }
    ];
  };

  services.borgbackup.repos = {
    cimmeria = {
      authorizedKeys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC7Sqwn2gEr4tezX89qO1GptKT4y+BPDKkBPtdmoUV06AiW4W5++6aYPlAUWKVqEZz0WyeX8tONbCDpZXzReL2wqS7NfGfz2zTXNMSVjPnjWzPF2pT9nG85COaUVfsxSqp9JK/z3j7NKlm0Y61LjoZozIFP9oZ5wGefrRgvZuBr4y1CKh+LqXgslgqZo4YnPMRcBA/f49YjQcpxpbVqWOFTVwaWczUJVklmdOMKUinMjxsgriexWmZcf+kgqCqVSuQ4SIyyeIpYGh1bGsiEJbI8GKilNp/gOrlz+shp+de8UKLZN38CYs9i9qRyKHyRLMQr/XqRT83vT/nXJn8O2ZtWiyKpR+5BucBfBZLtH9gNjzvICzaCA3lCkwpmLnbcQRqBPJ7S6xfdiSmf/lEmdZ348uFqPZttFlGTUq+XSzVGY56xAjvfAOlIsbSPKVPBDlcofFTXna4c+pAlsPcUjzFj2N1Ef8IPCtIJsy1Zpp1pk1AVF34dHiJqKxcxGojMifM= borg (cimmeria)"
      ];
      path = "/srv/borg/cimmeria";
    };

    aquilonia = {
      authorizedKeys = [
        (builtins.readFile (config.diffeq.secretsPath + /ssh/borg-aquilonia.pub))
      ];
      path = "/srv/borg/aquilonia";
    };

    medley = {
      authorizedKeys = [
        (builtins.readFile (config.diffeq.secretsPath + /ssh/borg-medley.pub))
      ];
      path = "/srv/borg/medley.domus.diffeq.com";
    };

    db = {
      authorizedKeys = [
        (builtins.readFile (config.diffeq.secretsPath + /ssh/borg-db.pub))
      ];
      path = "/srv/borg/db";
    };

    stygia = {
      authorizedKeys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCpp5ZV9pzigv9e4H520tAkHrfjH25A0CWJJ6FlNuRsSkcMhYmpJ6V4vv5vjUElnSidlr+cOIzka+XaP31ceRvVLXHfDYeHgfAjKMufgF6lpYJn6ENBfm/Q1wX1visMqJVX0MMywFHMMhpzJKavMWIr3WK6hocp7RbPmYiWqPJ3h1Jdj2LZXowNRVjJM0qARrNEmioCDN6xA+2MSedZY0pzSGpUCD5kfNnFO2KYY1jIcKrn9eoiXAeXoA7LvCtj3O4StLJST19XVzSczhcuAtAo+PNLh8QERiL/K02V7/U69r6jaFMA0+Fr3qJd8NYMsjhiShuNT9Oi7GAtpHLChmZkg5LTeqZ6huzSHLRs+MUwc/eF5/h4Srlnvhu2cL8rYVmmrkMqf+rdp34yozC2MtU++9Xxv/6ZrD4XZk1VoCFErFHMZXZB/pv2gXulstHtXmIVHrMQwWctzoJ8elMzTIQEGIjNAy2nR31qDuWqLiECSbU4oWNi95+fsrVtfPnS8Y0= borg (stygia)"
      ];
      path = "/srv/borg/stygia";
    };

    megahost-one = {
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGI6hdGD/VS7pPqdIiHKynFuXQgEnQ3VYKDhjZAyYB/b borg (megahost-one.diffeq.com)"
      ];
      path = "/srv/borg/megahost-one.diffeq.com";
    };

    mail = {
      authorizedKeys = [
        (builtins.readFile (config.diffeq.secretsPath + /ssh/borg-mail.pub))
      ];
      path = "/srv/borg/mail.domus.diffeq.com";
    };

    lubelogger = {
      authorizedKeys = [
        (builtins.readFile (config.diffeq.secretsPath + /ssh/borg-lubelogger.pub))
      ];
      path = "/srv/borg/lubelogger.domus.diffeq.com";
    };

    git = {
      authorizedKeys = [
        (builtins.readFile (config.diffeq.secretsPath + /ssh/borg-git.pub))
      ];
      path = "/srv/borg/git";
    };

    syncthing = {
      authorizedKeys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCh2TOy26BhEVg89+2ko+FsC0g98ypMJ82b/CWqPpPx7n4eAhc4q6kLiMwyueB/2+GjH8sl7LWjWW9nfHnWHcXRBVUYbiinjTvEvfloQROVad/ysYPRWX+YzkWNffpVcw3omBs/wm7cxYKxi49qayNEII+9CQd3eEiZSAEihit3l5KX5oBrKajPtXQ0n8DBH9+1Xz56nBW93sSVO81rRuI57cOoERSpQPuc+TR6Aq8QVmEMP4w3CuMYL3SaewW53pnnCXDJkHIQ6BRn3MrSwGiqgAgqn6KH32ZtAcfPqPYQV1p822ZpfeVdhP/hZdBkInY/RVL+mw7wSIIsyjuKZlgkdXGQzYq44toD7mbzXWG649p8gFM5ZFV2LX+sgYK7anQWdmcIH8hGfit0woxmLLT8qNIbvYYo+owOUY30oZmpv3Cf00eZMcNCbDJR3PTVKwyHnq1eDb3igPD4daFN9evRap0UWP8Ss274eWqNKEDBC5irwlC2Jq8f3FV/jsbMdVZCI8vULbUMpQPUZ6Wh8fDqrKKC3XvlrAH8kRB5RSqc/DLqDtTpD+joEXi5HB35DaYsU34k6DwGjmCSKjnOxn9WmRSaY+UO7VJhmk+1MR65GOTvO8FYWzgDk4mz3YjK+DDNXOUEE+Vnqo35uEW3RHA8vGzqoAGflrldaSfROn8t2Q== borg (syncthing)"
      ];
      path = "/srv/borg/syncthing";
    };
  };

  # TODO: figure out how to make this consistent with the host.
  users.users.borg.uid = 1001;
}
