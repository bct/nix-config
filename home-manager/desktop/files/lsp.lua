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
require'lspconfig'.pyright.setup{}

-- ruby
require'lspconfig'.sorbet.setup{
  cmd = { "srb", "tc", "--lsp", "--disable-watchman" }
}
