{ pkgs, lib, ... }:

{
  # Packages that should be installed to the user profile.
  home.packages = [
    # neovim needs xclip for clipboard access
    pkgs.xclip

    # for telescope
    pkgs.ripgrep

    # LSP servers
    pkgs.nodePackages.pyright
    pkgs.nil
    pkgs.hoonLanguageServer
    pkgs.gopls
    pkgs.terraform-ls
    pkgs.nodePackages.typescript-language-server
  ];

  programs.neovim = {
    enable = true;

    # a helpful reference for config: https://github.com/nvim-lua/kickstart.nvim/blob/master/init.lua
    extraLuaConfig = lib.fileContents ./files/vim/init.lua;
    extraConfig = lib.fileContents ./files/vim/extra-config.vim;

    plugins = let
      black-nvim = pkgs.vimUtils.buildVimPlugin {
          name = "black-nvim";
          src = pkgs.fetchFromGitHub {
            owner = "averms";
            repo = "black-nvim";
            rev = "8fb3efc562b67269e6f31f8653297f826534fa4b";
            sha256 = "sha256-pbbbkRD4ZFxTupmdNe1UYpI7tN6//GXUMll/jeCSUAg=";
          };
        };
        in with pkgs.vimPlugins;
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
        black-nvim

        # terraform
        vim-terraform
      ]; # Only loaded if programs.neovim.extraConfig is set

    withPython3 = true;

    extraPython3Packages = ps: with ps; [
      black
      flake8
    ];

    vimAlias = true;
  };

  home.file.".config/nvim/lua/lsp.lua".source = ./files/vim/lsp.lua;
}
