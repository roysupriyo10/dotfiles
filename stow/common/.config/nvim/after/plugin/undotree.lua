-- Don't load undotree config in VSCode or Cursor
if vim.g.vscode or vim.g.cursor then
	return
end

vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle)
