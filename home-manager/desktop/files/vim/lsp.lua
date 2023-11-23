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

-- nvim-cmp supports additional completion capabilities, so broadcast that to servers
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

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

-- python
require'lspconfig'.pyright.setup{
  capabilities = capabilities,
  on_attach = on_attach,
  settings = {
    python = {
      pythonPath = "/home/brendan/.local/share/virtualenvs/py-QrVFw7Jf/bin/python",
      analysis = {
        autoSearchPaths = true,
        diagnosticMode = "workspace",
        useLibraryCodeForTypes = true
      }
    }
  }
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

-- typescript
require'lspconfig'.tsserver.setup{
  capabilities = capabilities,
  on_attach = on_attach,
}
