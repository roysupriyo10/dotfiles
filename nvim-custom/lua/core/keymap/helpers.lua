local map = vim.keymap.set

-- copy file path to + register
map({ "n", "v" }, "<leader>fp", function()
  local path = vim.fn.expand("%:p")
  vim.fn.setreg("+", path)
end)

-- copy file path with selection line numbers
map({
  "v"
}, "<leader>fl", function()
  local path = vim.fn.expand("%:p")
  local start_line = vim.fn.line("v")
  local end_line = vim.fn.line(".")

  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end

  local result = string.format("L%d-%d", start_line, end_line)
  vim.fn.setreg("+", path .. "#" .. result)
end)

-- this is for moving lines up/down when they are selected
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- this is for joining lines but keep cursor in last position
map("n", "J", "mzJ`z", { desc = "Join lines without moving cursor" })

-- don't write selected text in register after deletion
map("x", "<leader>p", [["_dP]], { desc = "Paste without overwrite" })

-- system clipboard
map({ "n", "v" }, "<leader>y", [["+y]], { desc = "Yank to clipboard" })
map("n", "<leader>Y", [["+Y]], { desc = "Yank line to clipboard" })

-- don't write deletes to register
map({ "n", "v" }, "<leader>d", [["_d]], { desc = "Delete to void register" })
map({ "n", "v" }, "<leader>D", [["_D]], { desc = "Delete line to void register" })
