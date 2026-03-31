-- Don't load nx config in VSCode or Cursor
if vim.g.vscode or vim.g.cursor then
	return
end

-- require("nx").setup({
--   nx_cmd_root = "nx",
--   command_runner = require("nx.command-runners").terminal_command_runner(),
--   form_renderer = require("nx.form-renderers").telescope_form_renderer(),
--   read_init = true,
-- })
