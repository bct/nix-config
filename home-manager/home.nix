# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)

{ outputs, pkgs, ... }: {
  imports = [
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

  home = {
    username = "bct";
    homeDirectory = "/home/bct";
  };

  home.packages = [
    # xmonad, xmobar, and supporting packages
    pkgs.xmobar
    (pkgs.unstable.nerdfonts.override { fonts = [ "UbuntuMono" ]; })
    pkgs.ubuntu_font_family

    # backlight control
    pkgs.light

    # utilities
    pkgs.silver-searcher

    # screen locking
    pkgs.xss-lock
    # would like to have sxlock too but it's unpackaged

    # background
    pkgs.feh
  ];

  fonts.fontconfig.enable = true;

  home.sessionVariables = {
    EDITOR = "vim";
    LANG = "en_CA.utf8";

    # nix needs this (on Arch)
    LOCALE_ARCHIVE = "/usr/lib/locale/locale-archive";
  };

  home.shellAliases = {
    aoeu = "setxkbmap us";
    asdf = "setxkbmap dvorak";

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

      /usr/lib/xdg-desktop-portal-gtk &
      systemctl --user start xdg-desktop-portal &

      setxkbmap dvorak
    '';

    windowManager = {
      xmonad = {
        enable = true;
        enableContribAndExtras = true;
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

      set -o vi

      # make ^L work
      bind -m vi-insert 'Control-l: clear-screen'

      export PATH=$PATH:/home/bct/.local/share/gem/ruby/3.0.0/bin

      export NIX_PATH=$HOME/.nix-defexpr/channels:/nix/var/nix/profiles/per-user/root/channels''${NIX_PATH:+:$NIX_PATH}
    '';
  };

  programs.git = {
    enable = true;
    userName = "Brendan Taylor";
    userEmail = "bct@diffeq.com";

    aliases = {
      cobu = "!git checkout -b \${1:-tmp} && git bru \${2:-origin}";
      lol = "log --graph --pretty=format:\"%C(yellow)%h%Creset%C(cyan)%C(bold)%d%Creset %C(cyan)(%cr)%Creset %C(green)%ce%Creset %s\"";
      lola = "log --graph --all --pretty=format:\"%C(yellow)%h%Creset%C(cyan)%C(bold)%d%Creset %C(cyan)(%cr)%Creset %C(green)%ce%Creset %s\"";
    };

    extraConfig = {
      init.defaultBranch = "master";
      rebase.autosquash = true;
    };

    ignores = [
      ".*.s[a-w][a-z]"
      ".s[a-w][a-z]"
    ];
  };

  programs.readline = {
    enable = true;
    variables = {
      editing-mode = "vi";
      keymap = "vi";
    };
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
  home.file.".xmonad/xmonad.hs".source = ./files/xmonad.hs;
  home.file.".xmobarrc".source = ./files/xmobarrc.hs;

  home.file.".alacritty.yml".source = ./files/alacritty.yml;

  home.file.".ssh/config".text = ''
    # 2022-08-06 many hosts (e.g. mi-go) don't have alacritty terminfo
    Host *
      SetEnv TERM=xterm-256color
  '';

  # scale browser UIs.
  # maybe I should figure out how to scale the UI more generally?
  home.file.".config/brave-flags.conf".text = ''
    --force-device-scale-factor=1.5
  '';

  home.file.".config/chromium-flags.conf".text = ''
    --force-device-scale-factor=1.5
  '';

  # Enable home-manager and git
  programs.home-manager.enable = true;

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
