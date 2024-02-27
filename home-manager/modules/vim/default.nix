{ pkgs, lib, ... }:

{
  # Packages that should be installed to the user profile.
  home.packages = let
    pyright = pkgs.nodePackages.pyright.override rec {
      version = "1.1.347";
      src = pkgs.fetchurl {
        url = "https://registry.npmjs.org/pyright/-/pyright-${version}.tgz";
        sha256 = "sha256-Ie1TsCjIZLSKdmBaJwk5o7JG0Pqtwr6qz9iuJZd8Odw=";
      };
    };
  in [
    # neovim needs xclip for clipboard access
    pkgs.xclip

    # for telescope
    pkgs.ripgrep

    # formatters
    pkgs.nodePackages.prettier

    # LSP servers
    pyright
    pkgs.nil
    pkgs.hoonLanguageServer
    pkgs.gopls
    pkgs.unstable.ruff-lsp
    pkgs.terraform-ls
    pkgs.nodePackages.vscode-langservers-extracted
    pkgs.nodePackages.typescript-language-server
  ];

  programs.neovim = {
    enable = true;

    # a helpful reference for config: https://github.com/nvim-lua/kickstart.nvim/blob/master/init.lua
    extraLuaConfig = lib.fileContents ./files/init.lua;
    extraConfig = lib.fileContents ./files/extra-config.vim;

    plugins = with pkgs.vimPlugins; let
      arrow-nvim = pkgs.vimUtils.buildVimPlugin {
        pname = "arrow.nvim";
        version = "2024-02-21";
        src = pkgs.fetchFromGitHub {
          owner = "otavioschwanck";
          repo = "arrow.nvim";
          rev = "79527117368995b81aa1a77714b49d0d7535274b";
          sha256 = "sha256-+CG9Ox3Sct7rKszxhOuHS70UgvlrdnQzeHGivUtDU5M=";
        };
        meta.homepage = "https://github.com/otavioschwanck/arrow.nvim";
      };
    in [
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
            local conform = require 'conform'

            conform.setup({
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

            conform.format { async = true, lsp_fallback = true }

            local jsLangs = {"javascript", "json", "typescript", "typescriptreact"}
            for _, lang in ipairs(jsLangs)
            do
              conform.formatters_by_ft[lang] = { "prettier"}
            end
          '';
        }

        # git
        vim-fugitive

        {
          plugin = which-key-nvim;
          type = "lua";
          config = ''
            require("which-key").setup {
            }
          '';
        }

        {
          plugin = arrow-nvim;
          type = "lua";
          config = ''
            require('arrow').setup({
              show_icons = false,
              leader_key = ';' -- Recommended to be a single key
            })
          '';
        }

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
