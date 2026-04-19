-- this file will mainly contain lsp keymaps

local map = vim.keymap.set
local fzf = function() return require("fzf-lua") end

-- format command, removed since conform.nvim handles formatting overrides
-- map("n", "<leader>ff", vim.lsp.buf.format, { desc = "Format buffer (LSP)" })

-- quickfix navigation
map("n", "<C-k>", "<cmd>cnext<CR>zz", { desc = "Next quickfix" })
map("n", "<C-j>", "<cmd>cprev<CR>zz", { desc = "Prev quickfix" })
map("n", "<leader>k", "<cmd>lnext<CR>zz", { desc = "Next loclist" })
map("n", "<leader>j", "<cmd>lprev<CR>zz", { desc = "Prev loclist" })

-- file rename by string
map("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = "Search/replace word" })
map("v", "<leader>s", [["zy:%s/<C-r>z/<C-r>z/gI<Left><Left><Left>]], { desc = "Search/replace selection" })

-- diagnostics navigation
map("n", "[d", function()
  vim.diagnostic.jump({ count = -1, float = true })
end, { desc = "Prev diagnostic" })
map("n", "]d", function()
  vim.diagnostic.jump({ count = 1, float = true })
end, { desc = "Next diagnostic" })

-- toggle open diagnostics floating panel
map("n", "<leader>dd", function() fzf().diagnostics_document() end, { desc = "Buffer diagnostics" })

-- common helpers for lsp
map("n", "<leader>vrn", vim.lsp.buf.rename, { desc = "Rename symbol" })
map("n", "<leader>vrr", vim.lsp.buf.references, { desc = "LSP references" })
map("n", "<leader>ca", function()
  fzf().lsp_code_actions({
    context = {
      "quickfix",
      "refactor",
      "source",
      "source.organizeImports",
      "source.fixAll",
      "source.addMissingImports",
    }
  })
end, { desc = "Code action" })
map("n", "gr", function() fzf().lsp_references() end, { desc = "References" })
map("n", "gi", function() fzf().lsp_implementations() end, { desc = "Implementations" })
map("n", "gt", function() fzf().lsp_typedefs() end, { desc = "Type definitions" })

-- import helpers (ts_ls source actions)
map("n", "<leader>ia", function()
  vim.lsp.buf.code_action({
    apply = true,
    ---@diagnostic disable-next-line
    context = { diagnostics = {}, only = { "source.addMissingImports.ts" } },
  })
end, { desc = "Add all missing imports" })
map("n", "<leader>io", function()
  vim.lsp.buf.code_action({
    apply = true,
    ---@diagnostic disable-next-line
    context = { diagnostics = {}, only = { "source.organizeImports.ts" } },
  })
end, { desc = "Organize imports" })
map("n", "<leader>iu", function()
  vim.lsp.buf.code_action({
    apply = true,
    ---@diagnostic disable-next-line
    context = { diagnostics = {}, only = { "source.removeUnusedImports.ts" } },
  })
end, { desc = "Remove unused imports" })
