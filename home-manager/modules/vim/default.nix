{ pkgs, lib, ... }:

{
  # Packages that should be installed to the user profile.
  home.packages = let
    pyright = pkgs.nodePackages.pyright.override rec {
      version = "1.1.357";
      src = pkgs.fetchurl {
        url = "https://registry.npmjs.org/pyright/-/pyright-${version}.tgz";
        sha256 = "sha256-2xSICMxrszkqtYqvSg/81fc951LHARPqHaht/Bk5Yi4=";
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

      telescope-alternate-nvim = pkgs.vimUtils.buildVimPlugin {
        pname = "telescope-alternate.nvim";
        version = "2024-04-15";
        src = pkgs.fetchFromGitHub {
          owner = "otavioschwanck";
          repo = "telescope-alternate.nvim";
          rev = "2efa87d99122ee1abe8ada1a50304180a1802c34";
          sha256 = "sha256-oit93iNRGlQhKAgsy0JgaJLkf+1miDhi3XjzE39gx7g=";
        };
        meta.homepage = "https://github.com/otavioschwanck/telescope-alternate.nvim";
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

            -- not sure why black is so slow, that may require investigation
            -- https://github.com/stevearc/conform.nvim/blob/master/doc/recipes.md#automatically-run-slow-formatters-async
            local slow_format_filetypes = {"python"}

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

              format_on_save = function(bufnr)
                if slow_format_filetypes[vim.bo[bufnr].filetype] then
                  return
                end
                local function on_format(err)
                  if err and err:match("timeout$") then
                    slow_format_filetypes[vim.bo[bufnr].filetype] = true
                  end
                end

                return { timeout_ms = 200, lsp_fallback = true }, on_format
              end,

              format_after_save = function(bufnr)
                if not slow_format_filetypes[vim.bo[bufnr].filetype] then
                  return
                end
                return { lsp_fallback = true }
              end,
            })

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
          # Bookmark your files, separated by project, and quickly navigate through them.
          plugin = arrow-nvim;
          type = "lua";
          config = ''
            require('arrow').setup({
              show_icons = false,
              leader_key = ';' -- Recommended to be a single key
            })
          '';
        }

        {
          # Alternate between common files using pre-defined regexp.
          plugin = telescope-alternate-nvim;
          type = "lua";
          config = ''
            require('telescope-alternate').setup({
              mappings = {
                { '(.*)/(.*).py', { { '[1]/tests/[2]_test.py', 'Test' } } },
                { '(.*)/tests/(.*)_test.py', { { '[1]/[2].py', 'Original', true } } },
              },
              presets = { }, -- Telescope pre-defined mapping presets
              open_only_one_with = 'current_pane',
            })

            require('telescope').load_extension('telescope-alternate')

            vim.keymap.set('n', '<leader>a', ':Telescope telescope-alternate alternate_file<cr>', { desc = 'Go to [a]lternate file' })
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
