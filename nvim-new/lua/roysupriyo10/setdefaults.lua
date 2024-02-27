vim.opt.guicursor = ''

vim.opt.nu = true
vim.opt.relativenumber = true

vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true

vim.opt.smartindent = true

vim.opt.wrap = false

vim.opt.ignorecase = true

vim.opt.swapfile = false
vim.opt.backup = false
-- vim.opt.undodir = os.getenv 'HOME' .. '/.vim/undodir'
vim.opt.undofile = true

vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.termguicolors = true

vim.opt.scrolloff = 8
vim.opt.signcolumn = 'yes'
vim.opt.isfname:append '@-@'

vim.opt.updatetime = 50

vim.opt.colorcolumn = '80'

-- local create_autocmd = vim.api.nvim_create_autocmd
-- local create_augroup = vim.api.nvim_create_augroup
--
-- create_augroup("Prettier", {clear=true})
-- create_autocmd("BufWritePost", {
--   pattern = {"*.js", "*.ts", "*.jsx", "*.tsx"},
--   group = "Prettier",
--   callback = function()
--     local cursor = vim.api.nvim_win_get_cursor(0)
--     vim.cmd("silent!%!prettier %")
--     vim.api.nvim_win_set_cursor(0, cursor)
--   end
-- })
--
