{ pkgs, lib, ... }:

{
  # Packages that should be installed to the user profile.
  home.packages = [
    # neovim needs xclip for clipboard access
    pkgs.xclip

    # for telescope
    pkgs.ripgrep

    # LSP servers
    pkgs.unstable.nodePackages.pyright
    pkgs.nil
    pkgs.hoonLanguageServer
    pkgs.gopls
  ];

  programs.neovim = {
    enable = true;

    # a helpful reference for config: https://github.com/nvim-lua/kickstart.nvim/blob/master/init.lua
    extraLuaConfig = lib.fileContents ./files/vim/init.lua;
    extraConfig = lib.fileContents ./files/vim/extra-config.vim;

    plugins = with pkgs.vimPlugins;
      [
        gruvbox-community
        bufexplorer
        lightline-vim

        # telescope
        telescope-nvim
        telescope-fzf-native-nvim

        # completion
        nvim-cmp
        cmp-nvim-lsp

        # lsp
        nvim-lspconfig
        nvim-lightline-lsp

        # git
        vim-fugitive

        # -- language-specific
        # nix
        vim-nix

        # hoon
        hoon-vim

        # python
        vim-isort
      ]; # Only loaded if programs.neovim.extraConfig is set

    withPython3 = true;

    extraPackages = [
      (pkgs.python3.withPackages (ps: with ps; [
        black
        flake8
      ]))
    ];

    vimAlias = true;
  };

  home.file.".config/nvim/lua/lsp.lua".source = ./files/vim/lsp.lua;
}
