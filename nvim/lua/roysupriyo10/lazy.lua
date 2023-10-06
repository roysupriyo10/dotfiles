-- install lazy
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = ' '

-- list of plufins
local plugins = {
	{
		'nvim-telescope/telescope.nvim',
		-- tag = '0.1.2',
		branch = '0.1.x',
		dependencies = {
			'nvim-lua/plenary.nvim',
			{ "nvim-telescope/telescope-fzf-native.nvim", build = 'make' },
			'nvim-tree/nvim-web-devicons'
		},

	},

	{
		'rose-pine/neovim',
	},
	{
		'nvim-treesitter/nvim-treesitter',
		build = ':TSUpdate'
	},
	'mbbill/undotree',
	'tpope/vim-fugitive',
	{
		"hrsh7th/nvim-cmp",
		event = "InsertEnter",
		dependencies = {
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"L3MON4D3/LuaSnip",
			"saadparwaiz1/cmp_luasnip",
			"rafamadriz/friendly-snippets"
		},
		config = function()

			local cmp = require("cmp")

			local luasnip = require("luasnip")

			require("luasnip.loaders.from_vscode").lazy_load()

			cmp.setup({
				completion = {
					completeopt = "menu,menuone,preview,noselect",
				},
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end
				},

				mapping = cmp.mapping.preset.insert({
					['<C-k>'] = cmp.mapping.select_prev_item(),
					['<C-j>'] = cmp.mapping.select_next_item(),
					['<C-b>'] = cmp.mapping.scroll_docs(-4),
					['<C-f>'] = cmp.mapping.scroll_docs(4),
					['<C-Space>'] = cmp.mapping.complete(),
					['<C-e>'] = cmp.mapping.abort(),
					['<C-y>'] = cmp.mapping.confirm({ select = true }),
				}),
				sources = cmp.config.sources({
					{ name = 'nvim_lsp' },
					{ name = 'luasnip' },
					{ name = 'buffer' },
					{ name = 'path' },
				}),
			})
		end
	},
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { 'nvim-tree/nvim-web-devicons', lazy = true },
		config = function()
			require('lualine').setup {
				options = {
					icons_enabled = true,
					theme = 'auto',
          component_separators = { left = '|', right = '|'},
          section_separators = { left = '', right = ''},
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
					}
				},
				sections = {
					lualine_a = {'mode'},
					lualine_b = {'branch', 'diff', 'diagnostics'},
					lualine_c = {'filename'},
					lualine_x = {'encoding', 'filetype'},
					lualine_y = {'progress'},
					lualine_z = {'location'}
				},
				inactive_sections = {
					lualine_a = {},
					lualine_b = {},
					lualine_c = {'filename'},
					lualine_x = {'location'},
					lualine_y = {},
					lualine_z = {}
				},
				tabline = {},
				winbar = {},
				inactive_winbar = {},
				extensions = {}
			}
		end
	},
  --[[
  {
    'malbertzard/inline-fold.nvim',
    lazy = {
      defaultPlaceHolder = "...",
      queries = {
        html = {
          { pattern = 'class="([^"]*)"', placeholder = "@" }, -- classes in html
          { pattern = 'href="(.-)"' }, -- hrefs in html
          { pattern = 'src="(.-)"' }, -- HTML img src attribute
        },
        typescriptreact = {
          { pattern = 'className="([^"]*)"', placeholder = "@" }, -- classes in html
          { pattern = 'href="(.-)"' }, -- hrefs in html
          { pattern = 'src="(.-)"' }, -- HTML img src attribute
        }
      }
    },
    config = function ()
      vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWinEnter' }, {
        pattern = { '*.html', '*.tsx' },
        callback = function(_)
          if not require('inline-fold.module').isHidden then
            vim.cmd('InlineFoldToggle')
          end
        end,
      })
      require('inline-fold')
    end
  }
  --]]
}

require('lazy').setup({plugins, { import = "roysupriyo10.lsp" }}, {
	checker = {
		enabled = true,
		notify = false
	},
	change_detection = {
		notify = false
	}
})
