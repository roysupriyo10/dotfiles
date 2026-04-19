local opt = vim.opt

-- basic line numbering
opt.number = true
opt.relativenumber = true

-- indents
opt.tabstop = 2
opt.softtabstop = 2
opt.shiftwidth = 2
opt.smartindent = true
opt.expandtab = true

-- no line wraps
opt.wrap = false

-- search
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = false
opt.incsearch = true

-- appearance
opt.guicursor = ""
opt.cursorline = true
opt.termguicolors = true
opt.signcolumn = "yes"
opt.colorcolumn = "80"
opt.scrolloff = 8

-- default overrides
opt.swapfile = false
opt.backup = false
opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
opt.undofile = true

-- perf
opt.updatetime = 50

-- misc
opt.isfname:append("@-@")

-- folding
opt.foldcolumn = "1"
opt.foldlevel = 99
opt.foldlevelstart = 99
opt.foldenable = true
