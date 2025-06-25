-- Don't load fugitive config in VSCode or Cursor
if vim.g.vscode or vim.g.cursor then
	return
end

vim.keymap.set("n", "<leader>gs", vim.cmd.Git)
