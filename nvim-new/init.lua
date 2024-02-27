local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
end ---@diagnostic disable-next-line: undefined-field
vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
  'tpope/vim-sleuth', -- Detect tabstop and shiftwidth automatically
  {
    'terrortylor/nvim-comment',
    event = 'VeryLazy',
    config = function()
      require('nvim_comment').setup {
        comment_empty = true,
        live_mapping = 'gcc',
        operator_mapping = 'gc',
      }
    end,
  },
  { -- Useful plugin to show you pending keybinds.
    'folke/which-key.nvim',
    event = 'VeryLazy', -- Sets the loading event to 'VeryLazy'
    config = function() -- This is the function that runs, AFTER loading
      require('which-key').setup()

      vim.o.timeout = true
      vim.o.timeoutlen = 750

      -- Document existing key chains
      require('which-key').register {
        ['<leader>c'] = { name = '[C]ode', _ = 'which_key_ignore' },
        ['<leader>d'] = { name = '[D]ocument', _ = 'which_key_ignore' },
        ['<leader>r'] = { name = '[R]ename', _ = 'which_key_ignore' },
        ['<leader>s'] = { name = '[S]earch', _ = 'which_key_ignore' },
        ['<leader>w'] = { name = '[W]orkspace', _ = 'which_key_ignore' },
      }
    end,
  },
  {
    'tpope/vim-abolish',
  },
  { -- Fuzzy Finder (files, lsp, etc)
    'nvim-telescope/telescope.nvim',
    event = 'VeryLazy',
    branch = '0.1.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make',
        cond = function()
          return vim.fn.executable 'make' == 1
        end,
      },
      { 'nvim-tree/nvim-web-devicons' },
    },
    config = function()
      local telescope = require 'telescope'
      local actions = require 'telescope.actions'
      local builtin = require 'telescope.builtin'

      telescope.setup {
        defaults = {
          mappings = {
            i = {
              ['<C-k>'] = actions.move_selection_previous, --move to prev
              ['<C-j>'] = actions.move_selection_next, --move to next
              ['<C-q>'] = actions.send_selected_to_qflist + actions.open_qflist, --move to qflist
            },
          },
        },

        telescope.load_extension 'fzf',
      }

      -- essential keymaps
      vim.keymap.set('n', '<leader>pf', builtin.find_files, {})
      vim.keymap.set('n', '<leader>ps', builtin.live_grep, {})
      vim.keymap.set('n', '<leader>pw', builtin.grep_string, {})

      -- new keymaps try it
      vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })

      vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
      vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
      vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
      vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
      vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
      vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })

      vim.keymap.set('n', '<leader>s/', function()
        builtin.live_grep {
          grep_open_files = true,
          prompt_title = 'Live Grep in Open Files',
        }
      end, { desc = '[S]earch [/] in Open Files' })

      -- nvim config
      vim.keymap.set('n', '<leader>sn', function()
        builtin.find_files { cwd = vim.fn.stdpath 'config' }
      end, { desc = '[S]earch [N]eovim files' })
    end,
  },

  { -- LSP Configuration & Plugins
    'neovim/nvim-lspconfig',
    dependencies = {
      -- Automatically install LSPs and related tools to stdpath for neovim
      'williamboman/mason.nvim',
      'williamboman/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',

      -- Useful status updates for LSP.
      -- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
      { 'j-hui/fidget.nvim', opts = {} },
    },
    config = function()
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc)
            vim.keymap.set('n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end

          map('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')

          map('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')

          map('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')

          map('<leader>D', require('telescope.builtin').lsp_type_definitions, 'Type [D]efinition')

          map('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')

          map('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')

          map('<leader>d', vim.diagnostic.open_float, 'Show line diagnostics') -- show diagnostics for line

          map('[d', vim.diagnostic.goto_prev, 'Go to previous diagnostic') -- jump to previous diagnostic in buffer

          map(']d', vim.diagnostic.goto_next, 'Go to next diagnostic') -- jump to next diagnostic in buffer

          map('<leader>vrn', vim.lsp.buf.rename, '[R]e[n]ame')

          map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')

          map('K', vim.lsp.buf.hover, 'Hover Documentation')

          map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client.server_capabilities.documentHighlightProvider then
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              buffer = event.buf,
              callback = vim.lsp.buf.document_highlight,
            })

            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
              buffer = event.buf,
              callback = vim.lsp.buf.clear_references,
            })
          end
        end,
      })

      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities = vim.tbl_deep_extend('force', capabilities, require('cmp_nvim_lsp').default_capabilities())

      local servers = {
        html = {},
        tsserver = {
          filetypes = {
            'typescript',
            'typescriptreact',
            'typescript.tsx',
            'javascript',
            'javascriptreact',
            'javascript.tsx',
          },
          root_dir = require('lspconfig').util.root_pattern '.git',
        },
        cssls = {},
        tailwindcss = {},
        emmet_language_server = {
          filetypes = {
            'html',
            'typescriptreact',
            'javascriptreact',
            'css',
            'sass',
            'scss',
            'less',
            'svelte',
          },
        },
        lua_ls = {
          settings = {
            Lua = {
              runtime = { version = 'LuaJIT' },
              dianostics = {
                globals = { 'vim' },
              },
              workspace = {
                checkThirdParty = false,
                library = {
                  '${3rd}/luv/library',
                  unpack(vim.api.nvim_get_runtime_file('', true)),
                  [vim.fn.expand '$VIMRUNTIME/lua'] = true,
                  [vim.fn.stdpath 'config' .. '/lua'] = true,
                },
              },
            },
          },
        },
      }

      require('mason').setup()

      -- You can add other tools here that you want Mason to install
      -- for you, so that they are available from within Neovim.
      local ensure_installed = vim.tbl_keys(servers or {})
      vim.list_extend(ensure_installed, {
        'stylua', -- Used to format lua code
      })
      require('mason-tool-installer').setup { ensure_installed = ensure_installed }

      require('mason-lspconfig').setup {
        handlers = {
          function(server_name)
            local server = servers[server_name] or {}
            require('lspconfig')[server_name].setup {
              cmd = server.cmd,
              settings = server.settings,
              filetypes = server.filetypes,
              -- This handles overriding only values explicitly passed
              -- by the server configuration above. Useful when disabling
              -- certain features of an LSP (for example, turning off formatting for tsserver)
              capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {}),
            }
          end,
        },
      }
    end,
  },

  { -- Autoformat
    'stevearc/conform.nvim',
    opts = {
      notify_on_error = false,
      format_on_save = {
        timeout_ms = 500,
        lsp_fallback = true,
      },
      formatters_by_ft = {
        lua = { 'stylua' },
        javascript = { { 'prettierd', 'prettier' } },
        typescript = { { 'prettierd', 'prettier' } },
      },
    },
  },

  { -- Autocompletion
    'hrsh7th/nvim-cmp',
    event = 'InsertEnter',
    dependencies = {
      -- Snippet Engine & its associated nvim-cmp source
      'L3MON4D3/LuaSnip',
      'saadparwaiz1/cmp_luasnip',
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-buffer',
      'hrsh7th/cmp-path',
      'rafamadriz/friendly-snippets',
    },
    config = function()
      -- See `:help cmp`
      local cmp = require 'cmp'
      local luasnip = require 'luasnip'
      luasnip.config.setup {}
      require('luasnip.loaders.from_vscode').lazy_load()
      cmp.setup {
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        completion = { completeopt = 'menu,menuone,preview,noinsert,noselect' },

        mapping = cmp.mapping.preset.insert {
          ['<C-j>'] = cmp.mapping.select_next_item(),
          ['<C-k>'] = cmp.mapping.select_prev_item(),
          ['<C-y>'] = cmp.mapping.confirm { select = true },
          ['<C-b>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),

          ['<C-Space>'] = cmp.mapping.complete {},
          ['<C-l>'] = cmp.mapping(function()
            if luasnip.expand_or_locally_jumpable() then
              luasnip.expand_or_jump()
            end
          end, { 'i', 's' }),
          ['<C-h>'] = cmp.mapping(function()
            if luasnip.locally_jumpable(-1) then
              luasnip.jump(-1)
            end
          end, { 'i', 's' }),
        },
        sources = {
          { name = 'codeium' },
          { name = 'buffer' },
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
          { name = 'path' },
        },
      }
    end,
  },

  {
    'Exafunction/codeium.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'hrsh7th/nvim-cmp',
    },
    config = function()
      require('codeium').setup {}
    end,
  },

  -- Highlight todo, notes, etc in comments
  { 'folke/todo-comments.nvim', dependencies = { 'nvim-lua/plenary.nvim' }, opts = { signs = false } },

  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons', lazy = true },
    config = function()
      require('lualine').setup {
        options = {
          icons_enabled = true,
          theme = 'auto',
          component_separators = { left = '|', right = '|' },
          section_separators = { left = '', right = '' },
          disabled_filetypes = {
            statusline = {},
            winbar = {},
          },
          ignore_focus = {},
          always_divide_middle = true,
          globalstatus = false,
          refresh = {
            statusline = 1000,
            tabline = 1000,
            winbar = 1000,
          },
        },
        sections = {
          lualine_a = { 'mode' },
          lualine_b = { 'branch', 'diff', 'diagnostics' },
          lualine_c = { 'filename' },
          lualine_x = { 'encoding', 'filetype' },
          lualine_y = { 'progress' },
          lualine_z = { 'location' },
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = { 'filename' },
          lualine_x = { 'location' },
          lualine_y = {},
          lualine_z = {},
        },
        tabline = {},
        winbar = {},
        inactive_winbar = {},
        extensions = {},
      }
    end,
  },
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    priority = 1000,
  },

  { -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    config = function()
      ---@diagnostic disable-next-line: missing-fields
      require('nvim-treesitter.configs').setup {
        ensure_installed = { 'bash', 'c', 'html', 'lua', 'markdown', 'vim', 'vimdoc' },
        sync_install = false,
        -- Autoinstall languages that are not installed
        auto_install = true,
        highlight = { enable = true, additional_vim_regex_highlighting = false },
      }

      require('nvim-treesitter.install').prefer_git = true
    end,
  },
}, {})

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
--
--

-- set color scheme
function ColorSlate(color)
  color = color or 'catppuccin'
  -- color = color or "rose-pine"

  vim.cmd.colorscheme(color)

  vim.api.nvim_set_hl(0, 'Normal', { bg = 'none' })
  vim.api.nvim_set_hl(0, 'NormalFloat', { bg = 'none' })
  vim.api.nvim_set_hl(0, 'SignColumn', { bg = 'none' })
end

ColorSlate()

require 'roysupriyo10'
