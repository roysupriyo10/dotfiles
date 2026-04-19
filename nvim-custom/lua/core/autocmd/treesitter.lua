-- enable treesitter highlighting for all filetypes with a parser
vim.api.nvim_create_augroup("TreesitterHighlight", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  group = "TreesitterHighlight",
  callback = function()
    pcall(vim.treesitter.start)
  end,
})
