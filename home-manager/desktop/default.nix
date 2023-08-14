# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)

{ outputs, pkgs, ... }: {
  imports = [
    ../base
    ./vim.nix
  ];

  nixpkgs = {
    # You can add overlays here
    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages

      # If you want to use overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];

    # Configure your nixpkgs instance
    config = {
      allowUnfree = true;
      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = (_: true);
    };
  };

  nix = {
    package = pkgs.nix;

    settings = {
      # Enable flakes and new 'nix' command
      experimental-features = "nix-command flakes";
    };
  };

  home.packages = with pkgs; [
    # xmonad, xmobar, and supporting packages
    xmobar

    # things used by xmonad config:
    (nerdfonts.override { fonts = [ "UbuntuMono" ]; })
    ubuntu_font_family

    alacritty
    dmenu
    light

    # utilities
    htop
    silver-searcher
    ruby

    # screen locking
    xss-lock
    sxlock

    # background
    feh
  ];

  fonts.fontconfig.enable = true;

  home.sessionPath = [
    "$HOME/.local/share/gem/ruby/3.0.0/bin"
    "$HOME/bin"
  ];

  home.sessionVariables = {
    EDITOR = "vim";
    LANG = "en_CA.utf8";

    # scale chromium/brave browser UIs.
    # maybe I should figure out how to scale the UI more generally?
    CHROME_EXTRA_FLAGS = "--force-device-scale-factor=1.5";
  };

  home.shellAliases = {
    aoeu = "setxkbmap -layout us";
    asdf = "setxkbmap -layout us -variant dvorak";

    ls = "ls --color=auto";
    grep = "grep --color=auto";
  };

  xsession = {
    enable = true;
    initExtra = ''
      # hook up sxlock to the screen saver extension and systemd's login manager
      xss-lock -- sxlock &

      # set desktop background
      ~/.fehbg &

      xset dpms 0 120 180 &

      # set minimum brightness higher than 0
      light -N 0.1
    '';

    windowManager = {
      xmonad = {
        enable = true;
        enableContribAndExtras = true;
        config = ./files/xmonad/xmonad.hs;
        libFiles = {
          "Workspaces.hs" = ./files/xmonad/Workspaces.hs;
        };
      };
    };
  };

  programs.bash = {
    enable = true;
    historyControl = ["ignoredups"];
    initExtra = ''
      . /home/bct/.nix-profile/share/git/contrib/completion/git-prompt.sh

      # bct@cimmeria:~/projects/nixfiles (master) $
      PS1='\[\033[01;33m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\] $(__git_ps1 "(%s)")\$ '

      # If this is a GUI terminal, set the title to user@host:dir
      case "$TERM" in
      xterm*|rxvt*|alacritty*)
        PS1="\[\e]0;\u@\h: \w\a\]$PS1"
          ;;
      *)
          ;;
      esac

      # make ^L work
      bind -m vi-insert 'Control-l: clear-screen'

      export NIX_PATH=$HOME/.nix-defexpr/channels:/nix/var/nix/profiles/per-user/root/channels''${NIX_PATH:+:$NIX_PATH}
    '';
  };

  systemd.user.mounts.bulk = {
    Unit = {
      Description = "Mount /bulk";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };

    Install = { WantedBy = [ "default.target" ]; };

    Mount = {
      What = "mi-go.domus.diffeq.com:/mnt/bulk/media";
      Where = "/bulk";
      Type = "fuse.sshfs";
      Options = "_netdev,reconnect,ServerAliveInterval=30,ServerAliveCountMax=5,x-systemd.automount";
      TimeoutSec = 60;
    };
  };

  # Raw configuration files
  home.file.".xmobarrc".source = ./files/xmobarrc.hs;

  home.file.".alacritty.yml".source = ./files/alacritty.yml;

  home.file.".ssh/config".text = ''
    # 2022-08-06 many hosts (e.g. mi-go) don't have alacritty terminfo
    Host *
      SetEnv TERM=xterm-256color
  '';

  home.file."bin/mount-host".source = ./files/bin/mount-host;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  #
  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "22.11";
}
