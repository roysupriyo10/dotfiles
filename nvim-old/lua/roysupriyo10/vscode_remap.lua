local opts = {
	noremap = true,
	silent = true,
}

vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- remap space to leader
vim.keymap.set("n", "<Space>", "", opts)

-- copy to system clipboard
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])

-- do not put pasted over content in the buffer
vim.keymap.set("x", "<leader>p", [["_dP]])

-- delete but don't insert in vim clipboard buffer
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]])

-- for shifting lines up and down
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- for keeping cursor in the same place when appending lines from bottom
vim.keymap.set("n", "J", "mzJ`z")

-- for keeping cursor in the middle when navigating
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- go to explorer
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

-- disable irritating keymap
vim.keymap.set("n", "Q", "<nop>")

-- format keymap
vim.keymap.set("n", "<leader>ff", vim.lsp.buf.format)

-- run eslint and showcase results
vim.keymap.set("n", "<leader>ef", "mF:%!eslint_d --stdin --fix-to-stdout --stdin-filename %<CR>`F")

-- controls for moving between items
vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz")
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz")
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz")

-- search and replace word throughout file
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

-- vscode specific keymaps
vim.keymap.set({"n", "v"}, "<leader>pf", "<cmd>lua require('vscode').action('workbench.action.quickOpen')<CR>", opts)
vim.keymap.set({"n", "v"}, "<leader>ps", "<cmd>lua require('vscode').action('workbench.action.findInFiles')<CR>", opts)

-- add autocmd to enable cursor tab when entering insert mode
vim.api.nvim_create_autocmd("InsertEnter", {
  callback = function()
    require('vscode').action('editor.action.enableCppGlobally')
  end
})

-- add autocmd to disable cursor tab when leaving insert mode
vim.api.nvim_create_autocmd("InsertLeave", {
  callback = function()
    require('vscode').action('editor.cpp.disableenabled')
  end
})