return {
  {
    "neovim/nvim-lspconfig",
    lazy = false
  },

  {
    "williamboman/mason.nvim",
    cmd = "Mason",
    opts = {},
  },

  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = { "mason-org/mason.nvim", "neovim/nvim-lspconfig" },
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      ensure_installed = {
        "bashls",
        "clangd",
        "cssls",
        "dockerls",
        "eslint",
        "gopls",
        "html",
        "jsonls",
        "lua_ls",
        "pyright",
        "rust_analyzer",
        "tailwindcss",
        "ts_ls",
        "yamlls",
      },
      -- Automatically call vim.lsp.enable() for installed servers
      automatic_enable = true,
    },


  }
}
