local telescope = require('telescope')
local builtin = require('telescope.builtin')
local actions = require('telescope.actions')

-- builtin function remaps
vim.keymap.set('n', '<leader>pf', builtin.find_files, {})
vim.keymap.set('n', '<leader>rf', builtin.oldfiles, {})
vim.keymap.set('n', '<C-p>', builtin.git_files, {})
vim.keymap.set('n', '<leader>fc', builtin.grep_string, {})
vim.keymap.set('n', '<leader>ps', builtin.live_grep, {})
vim.keymap.set('n', '<leader>pw', function()
	builtin.grep_string({ search = vim.fn.input("Grep > ") });
end, {})


-- action remaps
telescope.setup({
	defaults = {
		mappings = {
			i = {
				["<C-k>"] = actions.move_selection_previous, --move to prev
				["<C-j>"] = actions.move_selection_next, --move to next
				["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist, --move to qflist
			}
		}
	},

	telescope.load_extension('fzf')
})
