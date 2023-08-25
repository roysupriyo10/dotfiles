local b = require('telescope.builtin')

vim.keymap.set('n', '<leader>pf', function()

  b.find_files(
    {
      hidden = true,
      no_ignore = true,
      file_ignore_patterns = {
        "node_modules",
        "build",
        "dist",
        "yarn.lock",
        ".cache",
        ".git",
        "pnpm-lock.yaml"
      }
    }
  )
end, {})

vim.keymap.set('n', "<C-p>", b.git_files, {})
vim.keymap.set('n', "<leader>ps", function()
  b.grep_string({ search = vim.fn.input("Grep > ") });
end)

