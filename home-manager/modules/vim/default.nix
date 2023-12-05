{ pkgs, lib, ... }:

{
  # Packages that should be installed to the user profile.
  home.packages = [
    # neovim needs xclip for clipboard access
    pkgs.xclip

    # for telescope
    pkgs.ripgrep

    # formatters
    pkgs.nodePackages.prettier

    # LSP servers
    pkgs.unstable.nodePackages.pyright
    pkgs.nil
    pkgs.hoonLanguageServer
    pkgs.gopls
    pkgs.terraform-ls
    pkgs.nodePackages.vscode-langservers-extracted
    pkgs.nodePackages.typescript-language-server
  ];

  programs.neovim = {
    enable = true;

    # a helpful reference for config: https://github.com/nvim-lua/kickstart.nvim/blob/master/init.lua
    extraLuaConfig = lib.fileContents ./files/init.lua;
    extraConfig = lib.fileContents ./files/extra-config.vim;

    plugins = with pkgs.vimPlugins;
      [
        gruvbox-community
        bufexplorer
        lightline-vim

        # telescope
        telescope-nvim
        telescope-fzf-native-nvim

        # completion
        {
          plugin = nvim-cmp;
          type = "lua";
          config = ''
            -- [[ Configure nvim-cmp ]]
            -- See `:help cmp`
            local cmp = require 'cmp'
            cmp.setup {
              completion = {
                completeopt = 'menu,menuone,noinsert',
              },
              mapping = cmp.mapping.preset.insert {
                ['<C-n>'] = cmp.mapping.select_next_item(),
                ['<C-p>'] = cmp.mapping.select_prev_item(),
                ['<C-d>'] = cmp.mapping.scroll_docs(-4),
                ['<C-f>'] = cmp.mapping.scroll_docs(4),
                ['<C-e>'] = cmp.mapping.close(),
                ['<C-Space>'] = cmp.mapping.complete {},
                ['<CR>'] = cmp.mapping.confirm {
                  behavior = cmp.ConfirmBehavior.Replace,
                  select = true,
                },
                ['<Tab>'] = cmp.mapping(function(fallback)
                  if cmp.visible() then
                    cmp.select_next_item()
                  else
                    fallback()
                  end
                end, { 'i', 's' }),
                ['<S-Tab>'] = cmp.mapping(function(fallback)
                  if cmp.visible() then
                    cmp.select_prev_item()
                  else
                    fallback()
                  end
                end, { 'i', 's' }),
              },
              sources = {
                { name = 'nvim_lsp' },
              },
            }
          '';
        }
        cmp-nvim-lsp

        # lsp
        nvim-lspconfig
        nvim-lightline-lsp

        # formatting
        {
          plugin = pkgs.unstable.vimPlugins.conform-nvim;
          type = "lua";
          config = ''
            require("conform").setup({
              formatters = {
                black = { command = "${pkgs.black}/bin/black" },
                isort = { command = "${pkgs.isort}/bin/isort" },
                prettier = { command = "${pkgs.nodePackages.prettier}/bin/prettier" },
              },
              formatters_by_ft = {
                -- run isort, then black
                python = { "isort", "black" },
              },
              format_on_save = {
                -- These options will be passed to conform.format()
                timeout_ms = 500,
                lsp_fallback = true,
              },
            })

            local jsLangs = {"javascript", "json", "typescript", "typescriptreact"}
            for _, lang in ipairs(jsLangs)
            do
              require("conform").formatters_by_ft[lang] = { "prettier"}
            end
          '';
        }

        # git
        vim-fugitive

        # -- language-specific
        # nix
        vim-nix

        # hoon
        hoon-vim

        # terraform
        vim-terraform
      ]; # Only loaded if programs.neovim.extraConfig is set

    withPython3 = true;

    extraPython3Packages = ps: with ps; [
      flake8
    ];

    vimAlias = true;
  };

  # TODO: programs.neovim.runtime."lsp.lua" ?
  home.file.".config/nvim/lua/lsp.lua".source = ./files/lsp.lua;
}
