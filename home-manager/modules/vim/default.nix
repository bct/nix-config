{ pkgs, lib, ... }:

{
  home.packages = [
    pkgs.wl-clipboard # clipboard provider for Wayland
    pkgs.xclip # clipboard provider for X
  ];

  programs.neovim = {
    enable = true;

    # a helpful reference for config: https://github.com/nvim-lua/kickstart.nvim/blob/master/init.lua
    initLua = lib.fileContents ./files/init.lua;
    extraConfig = lib.fileContents ./files/extra-config.vim;

    extraPackages = [
      # for telescope
      pkgs.ripgrep

      # formatters
      pkgs.prettier
      pkgs.nixfmt

      # LSP servers
      pkgs.pyright
      pkgs.nil
      pkgs.nixd
      pkgs.hoonLanguageServer
      pkgs.gopls
      pkgs.ruff
      pkgs.terraform-ls
      pkgs.tflint
      pkgs.vscode-langservers-extracted
      pkgs.typescript-language-server
      pkgs.rust-analyzer
      pkgs.clang-tools
      pkgs.emmylua-ls
    ];

    plugins =
      with pkgs.vimPlugins;
      let
        # -- unpackaged plugins
        telescope-alternate-nvim = pkgs.vimUtils.buildVimPlugin {
          pname = "telescope-alternate.nvim";
          version = "2024-04-15";
          src = pkgs.fetchFromGitHub {
            owner = "otavioschwanck";
            repo = "telescope-alternate.nvim";
            rev = "2efa87d99122ee1abe8ada1a50304180a1802c34";
            sha256 = "sha256-oit93iNRGlQhKAgsy0JgaJLkf+1miDhi3XjzE39gx7g=";
          };
          buildInputs = [ telescope-nvim ];
          meta.homepage = "https://github.com/otavioschwanck/telescope-alternate.nvim";
        };
      in
      [
        gruvbox-community
        bufexplorer

        {
          plugin = lualine-nvim;
          type = "lua";
          config = builtins.readFile ./plugins/lualine-nvim.lua;
        }

        # telescope
        telescope-nvim
        telescope-fzf-native-nvim

        # completion
        {
          plugin = blink-cmp;
          type = "lua";
          config = builtins.readFile ./plugins/blink-cmp.lua;
        }

        # lsp
        nvim-lspconfig

        # formatting
        {
          plugin = pkgs.vimPlugins.conform-nvim;
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
                prettier = { command = "${pkgs.prettier}/bin/prettier" },
                stylua = { command = "${pkgs.stylua}/bin/stylua" },
              },

              formatters_by_ft = {
                lua = { "stylua" },
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
            local exclude_test_file = function()
              return not string.match(vim.api.nvim_buf_get_name(0), ".*_test.py")
            end

            require('telescope-alternate').setup({
              mappings = {
                { '(.*)/(.*).py', { { '[1]/tests/[2]_test.py', 'Test', exclude_test_file } } },
                { '(.*)/tests/(.*)_test.py', { { '[1]/[2].py', 'Original' } } },
              },
              presets = { }, -- Telescope pre-defined mapping presets
              open_only_one_with = 'current_pane',
            })

            require('telescope').load_extension('telescope-alternate')

            vim.keymap.set('n', '<leader>x', ':Telescope telescope-alternate alternate_file<cr>', { desc = 'Go to [a]lternate file' })
          '';
        }

        # used by oil-nvim
        {
          plugin = mini-icons;
          type = "lua";
          config = ''
            require("mini.icons").setup()
          '';
        }

        {
          plugin = oil-nvim;
          type = "lua";
          config = ''
            require("oil").setup({
              view_options = {
                show_hidden = true,
              },
              git = {
                mv = function(src_path, dest_path)
                  return true
                end,
                rm = function(path)
                  return true
                end,
              },
            })
          '';
        }

        # -- LLM
        pkgs.vimPlugins.nui-nvim
        nvim-treesitter
        dressing-nvim
        plenary-nvim

        {
          plugin = render-markdown-nvim;
          type = "lua";
          config = ''
            require('render-markdown').setup({
              file_types = {
                "markdown",
                "Avante",
              };
            })
          '';
        }

        # {
        #   plugin = pkgs.vimPlugins.avante-nvim;
        #   type = "lua";
        #   config = builtins.readFile ./plugins/avante.lua;
        # }

        # -- note taking
        plenary-nvim # obsidian-nvim depends on this

        {
          plugin = obsidian-nvim;
          type = "lua";
          config = ''
            require("obsidian").setup({
              legacy_commands = false,
              workspaces = {
                {
                  name = "notes",
                  path = "~/projects/obsidian/notes/",
                },
              },
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
    withRuby = false;

    extraPython3Packages =
      ps: with ps; [
        flake8
      ];

    vimAlias = true;
  };

  # TODO: programs.neovim.runtime."lsp.lua" ?
  home.file.".config/nvim/lua/lsp.lua".source = ./files/lsp.lua;
}
