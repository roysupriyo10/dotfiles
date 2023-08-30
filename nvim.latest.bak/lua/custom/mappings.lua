---@type MappingsTable
local M = {}

M.dap = {
  plugin = true,
  n = {
    ["<leader>db"] = {
      "<cmd> DapToggleBreakpoint <CR>",
      "Add breakpoint at line",
    },
    ["<leader>dr"] = {
      "<cmd> DapContinue <CR>",
      "Start or continue the debugger",
    },
    ["<leader>cr"] = {
      "<cmd>lua require('nvterm.terminal').send('clang++ ' .. vim.fn.expand('%') .. '\\r && ./a.out', 'float')<CR>", "Run current C++ file in terminal"
    },
  }
}

M.general = {
  n = {
    [";"] = { ":", "enter command mode", opts = { nowait = true } },
  },
}

-- more keybinds!

return M
