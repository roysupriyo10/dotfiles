vim.opt.guicursor = ''

vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.mouse = 'a'

vim.opt.showmode = false

vim.opt.breakindent = true

vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true

vim.opt.smartindent = true

vim.opt.wrap = false

vim.opt.ignorecase = false
vim.opt.smartcase = true

vim.opt.swapfile = false
vim.opt.backup = false
-- vim.opt.undodir = os.getenv 'HOME' .. '/.vim/undodir'
vim.opt.undofile = true

vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

vim.opt.termguicolors = true

vim.opt.scrolloff = 8
vim.opt.signcolumn = 'yes'
vim.opt.isfname:append '@-@'

vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

vim.opt.inccommand = 'split'

vim.opt.cursorline = true

vim.opt.updatetime = 50
vim.opt.timeoutlen = 60

vim.opt.splitright = true
vim.opt.splitbelow = true

vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

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
