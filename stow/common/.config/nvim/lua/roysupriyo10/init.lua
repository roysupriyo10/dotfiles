if vim.g.vscode then
  require("roysupriyo10.vscode_remap")
else
  require("roysupriyo10.remap")
end

if vim.g.cursor or vim.g.vscode then
else
  require("roysupriyo10.lazy")
end

if vim.g.cursor or vim.g.vscode then
else
  require("roysupriyo10.setdefaults")
end