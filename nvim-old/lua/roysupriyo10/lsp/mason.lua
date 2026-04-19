return {
	"williamboman/mason.nvim",
	dependencies = {
		"williamboman/mason-lspconfig.nvim",
	},
	config = function()
		local mason = require("mason")

		local mason_lspconfig = require("mason-lspconfig")

		mason.setup({
			ui = {
				icons = {
					package_installed = "✓",
					package_pending = "→",
					package_uninstalled = "×",
				},
			},
		})

		mason_lspconfig.setup({
			ensure_installed = {
				"clangd",
				"pyright",
				"gopls",
				"html",
				"ts_ls",
				"cssls",
				"jdtls",
				"tailwindcss",
				"emmet_language_server",
				"lua_ls",
				"eslint",
				"jsonls",
				"yamlls",
				"bashls",
				"dockerls",
				"rust_analyzer",
			},
			automatic_installation = true,
		})
	end,
}
