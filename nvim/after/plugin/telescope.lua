-- Don't load telescope config in VSCode or Cursor
if vim.g.vscode or vim.g.cursor then
	return
end

local telescope = require("telescope")
local builtin = require("telescope.builtin")
local actions = require("telescope.actions")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local action_state = require("telescope.actions.state")

-- builtin function remaps
vim.keymap.set("n", "<leader>pf", builtin.find_files, {})
vim.keymap.set("n", "<leader>rf", builtin.oldfiles, {})
vim.keymap.set("n", "<C-p>", builtin.git_files, {})
vim.keymap.set("n", "<leader>fc", builtin.grep_string, {})
vim.keymap.set("n", "<leader>pa", builtin.live_grep, {})
vim.keymap.set("n", "<leader>pb", function()
	builtin.buffers({ sort_lastused = true })
end, {})
vim.keymap.set("n", "<leader>ps", function()
	builtin.live_grep({
		additional_args = { "--sortr=modified" },
	})
end, {})
vim.keymap.set("n", "<leader>fe", function()
	local search = vim.fn.input("Extension > ")
	builtin.find_files({
		find_command = {
			"fd",
			".",
			"--extension",
			search,
			"--no-ignore",
		},
	})
end, {})
vim.keymap.set("n", "<leader>pw", function()
	builtin.grep_string({ search = vim.fn.input("Grep > ") })
end, {})

-- Claude Code file picker - inserts absolute path at cursor
local function claude_file_picker(opts)
	opts = opts or {}
	local restore_insert = opts.restore_insert or false
	-- Use CLAUDE_PROJECT_DIR if set (for temp files opened via ctrl+g), fallback to cwd
	local project_dir = vim.fn.getenv("CLAUDE_PROJECT_DIR")
	if project_dir == vim.NIL or project_dir == "" then
		project_dir = vim.fn.getcwd()
	end

	local excludes = ".git,node_modules,.cache,dist,build,.next,.nuxt,target,__pycache__,.venv"

	pickers
		.new({}, {
			prompt_title = "Insert File Path (" .. vim.fn.fnamemodify(project_dir, ":t") .. ")",
			finder = finders.new_async_job({
				command_generator = function(prompt)
					local cmd = { "fd", "--hidden", "--follow", "--color", "never" }
					for exclude in excludes:gmatch("[^,]+") do
						table.insert(cmd, "--exclude")
						table.insert(cmd, exclude)
					end
					if prompt and prompt ~= "" then
						-- Convert query to fuzzy pattern: "abc" -> "a.*b.*c"
						-- Ignore spaces unless escaped with backslash
						local cleaned = prompt:gsub("\\ ", "\0"):gsub(" ", ""):gsub("\0", " ")
						local chars = {}
						for c in cleaned:gmatch("[^%s]") do
							table.insert(chars, c)
						end
						if #chars > 0 then
							local pattern = table.concat(chars, ".*")
							table.insert(cmd, pattern)
						end
					end
					table.insert(cmd, project_dir)
					-- Debug logging
					local log = io.open("/tmp/telescope_debug.log", "a")
					if log then
						log:write("cmd: " .. table.concat(cmd, " ") .. "\n")
						log:close()
					end
					return cmd
				end,
				entry_maker = function(entry)
					return {
						value = entry,
						display = entry:gsub("^" .. vim.pesc(project_dir) .. "/", ""),
						ordinal = entry,
					}
				end,
			}),
			sorter = conf.generic_sorter({}),
			attach_mappings = function(prompt_bufnr)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local selection = action_state.get_selected_entry()
					if selection then
						vim.api.nvim_put({ selection.value }, "", false, true)
						if restore_insert then
							vim.schedule(function()
								vim.cmd("startinsert")
								vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Right>", true, false, true), "n", false)
							end)
						end
					end
				end)
				return true
			end,
		})
		:find()
end

vim.keymap.set("n", "<leader>cf", claude_file_picker, { desc = "Insert file path (Claude style)" })
vim.keymap.set("i", "<C-f>", function() claude_file_picker({ restore_insert = true }) end, { desc = "Insert file path (Claude style)" })

-- action remaps
telescope.setup({
	defaults = {
		mappings = {
			i = {
				["<C-k>"] = actions.move_selection_previous, --move to prev
				["<C-j>"] = actions.move_selection_next, --move to next
				["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist, --move to qflist
			},
		},
	},

	telescope.load_extension("fzf"),
})
