-- see https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md

--  This function gets run when an LSP attaches to a particular buffer.
--    That is to say, every time a new file is opened that is associated with
--    an lsp (for example, opening `main.rs` is associated with `rust_analyzer`) this
--    function will be executed to configure the current buffer
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
  callback = function(event)
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
})

-- golang
vim.lsp.enable('gopls')

-- hoon
vim.lsp.config('hoon_ls', {
  cmd = { "hoon-language-server", "-p", "8080", "-u", "http://127.0.0.1" }
})
vim.lsp.enable('hoon_ls')

-- nix
vim.lsp.enable('nil_ls')
vim.lsp.enable('nixd')

-- python
vim.lsp.enable('pyright')
vim.lsp.enable('ruff')

-- ruby
vim.lsp.config('sorbet', {
  cmd = { "srb", "tc", "--lsp", "--disable-watchman" }
})
vim.lsp.enable('sorbet')

-- terraform
vim.lsp.enable('terraformls')
vim.lsp.enable('tflint')

-- typescript
vim.lsp.enable('eslint')
vim.lsp.enable('ts_ls')

-- rust
vim.lsp.enable('rust_analyzer')
