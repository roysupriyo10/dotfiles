-- add more env filetypes, view them as sh
vim.api.nvim_create_augroup("EnvFiletype", { clear = true })
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  group = "EnvFiletype",
  pattern = { ".env", ".env.*", "*.env" },
  callback = function()
    vim.bo.filetype = "sh"
  end,
})
