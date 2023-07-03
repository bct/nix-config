-- see https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md
require'lspconfig'.pyright.setup{}
require'lspconfig'.nil_ls.setup{}
require'lspconfig'.sorbet.setup{
  cmd = { "srb", "tc", "--lsp", "--disable-watchman" }
}
require'lspconfig'.hoon_ls.setup{
  cmd = { "hoon-language-server", "-p", "8080", "-u", "http://127.0.0.1" }
}
require'lspconfig'.gopls.setup{}
