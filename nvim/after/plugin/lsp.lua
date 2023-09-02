local lsp = require('lsp-zero').preset({})

lsp.on_attach(function(client, bufnr)
  -- see :help lsp-zero-keybindings
  -- to learn the available actions
  lsp.default_keymaps({buffer = bufnr})
end)

-- (Optional) Configure lua language server for neovim
local lspconfig = require('lspconfig')

lspconfig.emmet_language_server.setup({
  filestypes = {
    'css',
    'html','javascript',
    'javascriptreact',
    'less',
    'sass',
    'scss',
    'pug',
    'typescriptreact',
    'vue'
  },
  init_options = {
    pereferences = {},

    showexpandedabbreviation = "always",
    showabbreviationsuggestions = true,
    showsuggestionsassnippets = false,
    syntaxprofiles = {},
    variables = {},
    excludelanguages = {},

  }

})

lspconfig.lua_ls.setup(lsp.nvim_lua_ls())


lsp.setup()
