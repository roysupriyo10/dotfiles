return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    { "antosha417/nvim-lsp-file-operations", config = true },
  },
  config = function()
    local lspconfig = require("lspconfig")

    local cmp_nvim_lsp = require("cmp_nvim_lsp")

    local keymap = vim.keymap

    local opts = { noremap = true, silent = true }

    local on_attach = function(client, bufnr)
      opts.buffer = bufnr

      -- set keybinds
      opts.desc = "Show LSP references"
      keymap.set("n", "<leader>vrr", vim.lsp.buf.references, opts) -- show definition, references

      opts.desc = "Go to declaration"
      keymap.set("n", "gD", function ()
        vim.cmd.vsplit();
        vim.cmd("wincmd l");
        require('telescope.builtin').lsp_definitions(
        --         {
          --           jump_type = "never",
          --         }
          )
        end, opts) -- go to declaration

        opts.desc = "Show LSP definitions"
        keymap.set("n", "gd", require('telescope.builtin').lsp_definitions, opts) -- show lsp definitions

        opts.desc = "Show LSP references"
        keymap.set("n", 'gr', require('telescope.builtin').lsp_references, opts)

        opts.desc = "Show LSP implementations"
        keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts) -- show lsp implementations

        opts.desc = "Show LSP type definitions"
        keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts) -- show lsp type definitions

        opts.desc = "See available code actions"
        keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts) -- see available code actions, in visual mode will apply to selection

        opts.desc = "Smart rename"
        keymap.set("n", "<leader>vrn", vim.lsp.buf.rename, opts) -- smart rename

        opts.desc = "Show buffer diagnostics"
        keymap.set("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", opts) -- show  diagnostics for file

        opts.desc = "Show line diagnostics"
        keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts) -- show diagnostics for line

        opts.desc = "Go to previous diagnostic"
        keymap.set("n", "[d", vim.diagnostic.goto_prev, opts) -- jump to previous diagnostic in buffer

        opts.desc = "Go to next diagnostic"
        keymap.set("n", "]d", vim.diagnostic.goto_next, opts) -- jump to next diagnostic in buffer

        opts.desc = "Show documentation for what is under cursor"
        keymap.set("n", "K", vim.lsp.buf.hover, opts) -- show documentation for what is under cursor

        opts.desc = "Restart LSP"
        keymap.set("n", "<leader>lr", ":LspRestart<CR>", opts) -- mapping to restart lsp if necessary
      end

      local capabilities = cmp_nvim_lsp.default_capabilities()

      local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
      for type, icon in pairs(signs) do
        local hl = "DiagnosticSign" .. type
        vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
      end


      lspconfig['clangd'].setup({
        capabilities = capabilities,
        on_attach = on_attach,
      })

      lspconfig['pyright'].setup({
        capabilities = capabilities,
        on_attach = on_attach,
      })

      lspconfig['gopls'].setup({
        capabilities = capabilities,
        on_attach = on_attach,
      })

      lspconfig['html'].setup({
        capabilities = capabilities,
        on_attach = on_attach,
      })

      lspconfig['ts_ls'].setup({
        filetypes = {
          "typescript",
          "typescriptreact",
          "typescript.tsx",
          "javascript",
          "javascriptreact",
          "javascript.tsx",
        },
        capabilities = capabilities,
        on_attach = on_attach,
        root_dir = lspconfig.util.root_pattern('.git')
      })
      lspconfig['cssls'].setup({
        capabilities = capabilities,
        on_attach = on_attach,
        settings = {
          css = {
            lint = {
              unkwownAtRules = "ignore",
            }
          }
        }
      })
      lspconfig['jdtls'].setup({
        capabilities = capabilities,
        on_attach = on_attach,
      })
      lspconfig['tailwindcss'].setup({
        capabilities = capabilities,
        on_attach = on_attach,
      })
      lspconfig['emmet_language_server'].setup({
        capabilities = capabilities,
        on_attach = on_attach,
        filetypes = {
          "html",
          "typescriptreact",
          "javascriptreact",
          "css",
          "sass",
          "scss",
          "less", 
          "svelte",
        },
      })
      lspconfig['lua_ls'].setup({
        capabilities = capabilities,
        on_attach = on_attach,
        settings = {
          Lua = {
            diagnostics = {
              globals = { "vim" }
            },
            workspace = {
              library = {
                [vim.fn.expand("$VIMRUNTIME/lua")] = true,
                [vim.fn.stdpath("config") .. "/lua"] = true,
              }
            }
          }
        }
      })
      lspconfig['eslint'].setup({
        filetypes = {
          "javascript",
          "javascriptreact",
          "typescript",
          "typescriptreact"
        },
        capabilities = capabilities,
        on_attach = on_attach,
        settings = {
          experimental = {
            unstable_config_lookup_from_file = true
          }
        }
      })
      lspconfig['jsonls'].setup({
        filetypes = {
          "json",
          "jsonc",
        },
        capabilities = capabilities,
        on_attach = on_attach,
        settings = {
          json = {
            schemas = {
              {
                fileMatch = { "package.json" },
                url = "https://json.schemastore.org/package.json"
              },
              {
                fileMatch = { "tsconfig*.json" },
                url = "https://json.schemastore.org/tsconfig.json"
              },
              {
                fileMatch = { ".eslintrc.json", ".eslintrc" },
                url = "https://json.schemastore.org/eslintrc.json"
              },
              {
                fileMatch = { ".prettierrc", ".prettierrc.json", "prettier.config.json" },
                url = "https://json.schemastore.org/prettierrc.json"
              },
              {
                fileMatch = {
                  ".babelrc",
                  ".babelrc.json",
                  "babel.config.json",
                },
                url = "https://json.schemastore.org/babelrc.json"

              },
              {
                fileMatch = {"now.json", "vercel.json"},
                url = "https://json.schemastore.org/now.json"
              },
              {
                fileMatch = {
                  ".stylelintrc",
                  ".stylelintrc.json",
                  "stylelint.config.json"
                },
                url = "http://json.schemastore.org/stylelintrc.json"
              }
            }
          }
        }
      })
    end
  }
