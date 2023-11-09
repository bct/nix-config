-- see https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md

-- golang
require'lspconfig'.gopls.setup{}

-- hoon
require'lspconfig'.hoon_ls.setup{
  cmd = { "hoon-language-server", "-p", "8080", "-u", "http://127.0.0.1" }
}

-- nix
require'lspconfig'.nil_ls.setup{}

-- python
require'lspconfig'.pyright.setup{
  settings = {
    python = {
      pythonPath = "/home/brendan/.local/share/virtualenvs/py-QrVFw7Jf/bin/python",
      analysis = {
        autoSearchPaths = true,
        diagnosticMode = "openFilesOnly",
        useLibraryCodeForTypes = true
      }
    }
  }
}

-- ruby
require'lspconfig'.sorbet.setup{
  cmd = { "srb", "tc", "--lsp", "--disable-watchman" }
}

-- keybindings
vim.api.nvim_set_keymap('n', '<leader>d[', '<cmd>lua vim.diagnostic.goto_prev()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>d]', '<cmd>lua vim.diagnostic.goto_next()<CR>', { noremap = true, silent = true })
