-- see https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md

--  This function gets run when an LSP connects to a particular buffer.
local on_attach = function(_, bufnr)
  -- NOTE: Remember that lua is a real programming language, and as such it is possible
  -- to define small helper and utility functions so you don't have to repeat yourself
  -- many times.
  --
  -- In this case, we create a function that lets us more easily define mappings specific
  -- for LSP related items. It sets the mode, buffer and description for us each time.
  local nmap = function(keys, func, desc)
    if desc then
      desc = 'LSP: ' .. desc
    end

    vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
  end

  nmap('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
  nmap('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')

  nmap('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
  nmap('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
  nmap('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
  nmap('<leader>D', require('telescope.builtin').lsp_type_definitions, 'Type [D]efinition')
  nmap('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
  nmap('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')

  -- See `:help K` for why this keymap
  nmap('K', vim.lsp.buf.hover, 'Hover Documentation')
  nmap('<C-k>', vim.lsp.buf.signature_help, 'Signature Documentation')

  -- Lesser used LSP functionality
  nmap('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
end

--  When you add blink.cmp, luasnip, etc. Neovim now has *more* capabilities.
--  So, we create new capabilities with blink.cmp, and then broadcast that to the servers.
local capabilities = require('blink.cmp').get_lsp_capabilities()

-- golang
require('lspconfig').gopls.setup{
  capabilities = capabilities,
  on_attach = on_attach
}

-- hoon
require'lspconfig'.hoon_ls.setup{
  capabilities = capabilities,
  on_attach = on_attach,
  cmd = { "hoon-language-server", "-p", "8080", "-u", "http://127.0.0.1" }
}

-- nix
require'lspconfig'.nil_ls.setup{
  capabilities = capabilities,
  on_attach = on_attach
}

require'lspconfig'.nixd.setup{
  capabilities = capabilities,
  on_attach = on_attach
}

-- python
require'lspconfig'.pyright.setup{
  capabilities = capabilities,
  on_attach = on_attach,
  settings = {
    python = {
      pythonPath = "/home/brendan/aa/src/py/.venv/bin/python",
      analysis = {
        autoSearchPaths = true,
        diagnosticMode = "workspace",
        useLibraryCodeForTypes = true
      }
    }
  }
}

require'lspconfig'.ruff.setup{
  capabilities = capabilities,
  on_attach = on_attach
}

-- ruby
require'lspconfig'.sorbet.setup{
  capabilities = capabilities,
  on_attach = on_attach,
  cmd = { "srb", "tc", "--lsp", "--disable-watchman" }
}

-- terraform
require'lspconfig'.terraformls.setup{
  capabilities = capabilities,
  on_attach = on_attach,
}

require'lspconfig'.tflint.setup{
  capabilities = capabilities,
  on_attach = on_attach,
}

-- typescript
require'lspconfig'.eslint.setup{
  capabilities = capabilities,
  on_attach = on_attach,
}

require'lspconfig'.ts_ls.setup{
  capabilities = capabilities,
  on_attach = on_attach,
}

-- ansible
require'lspconfig'.ansiblels.setup{
  capabilities = capabilities,
  on_attach = on_attach,
}

-- rust
require'lspconfig'.rust_analyzer.setup{
  capabilities = capabilities,
  on_attach = on_attach,
}
