-- Don't load treesitter config in VSCode or Cursor
if vim.g.vscode or vim.g.cursor then
	return
end

require("nvim-treesitter.configs").setup({
	ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "typescript", "javascript" },
	sync_install = false,
	auto_install = true,
	highlight = {
		enable = true,
		additional_vim_regex_highlighting = false,
	},
})
