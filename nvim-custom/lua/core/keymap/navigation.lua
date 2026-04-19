-- this file will mainly contain navigation keymaps

local map = vim.keymap.set
local fzf = function() return require("fzf-lua") end

-- netrw is the only explorer needed
map("n", "<leader>pv", vim.cmd.Ex, { desc = "Open netrw" })

-- keep cursor centered during page jumps
map("n", "<C-d>", "<C-d>zz", { desc = "Keep cursor centered in page down jump" })
map("n", "<C-u>", "<C-u>zz", { desc = "Keep cursor centered in page up jump" })

-- keep cursor centered during search navigations
map("n", "n", "nzzzv", { desc = "Keep cursor centered in search next jump" })
map("n", "N", "Nzzzv", { desc = "Keep cursor centered in search previous jump" })

-- map ctrl+c to escape, best decision ever
map("i", "<C-c>", "<Esc>")

-- file pickers
map("n", "<leader>pf", function() fzf().files() end, { desc = "Find files" })
map("n", "<C-p>", function() fzf().git_files() end, { desc = "Git files" })
map("n", "<leader>rf", function() fzf().oldfiles() end, { desc = "Recent files" })
map("n", "<leader>pb", function() fzf().buffers({ sort_lastused = true }) end, { desc = "Buffers" })

-- grep
map("n", "<leader>pa", function() fzf().live_grep() end, { desc = "Live grep" })
map("n", "<leader>fc", function() fzf().grep_cword() end, { desc = "Grep word under cursor" })
map("n", "<leader>pw", function()
  fzf().grep({ search = vim.fn.input("Grep > ") })
end, { desc = "Grep with input" })
map("n", "<leader>ps", function() fzf().live_grep() end, { desc = "Live grep (sorted)" })

-- go to definition
map("n", "gd", function() fzf().lsp_definitions() end, { desc = "Go to definition" })
map("n", "gD", function()
  vim.cmd.vsplit()
  vim.cmd("wincmd l")
  fzf().lsp_definitions()
end, { desc = "Go to definition in vsplit" })

-- git pickers
map("n", "<leader>gf", function() fzf().git_status() end, { desc = "Git modified files" })
map("n", "<leader>gl", function() fzf().git_commits() end, { desc = "Git log" })
map("n", "<leader>gb", function()
  fzf().git_bcommits({
    actions = {
      ["ctrl-o"] = function(selected)
        local commit = selected[1]:match("(%x+)")
        vim.fn.system({ "git", "add", "-A" })
        vim.fn.system({ "git", "stash" })
        vim.fn.system({ "git", "checkout", commit })
        vim.cmd("checktime")
        vim.notify("detached checkout " .. commit, vim.log.levels.INFO)
      end
    }
  })
end, { desc = "Git buffer log" })
map("n", "<leader>gc", function()
  fzf().git_branches({
    actions = {
      ["default"] = function(selected)
        local branch = selected[1]:match("[%*%s]*(%S+)")
        branch = branch:gsub("^remotes/origin/", ""):gsub("^origin/", "")
        vim.fn.system({ "git", "add", "-A", })
        vim.fn.system({ "git", "stash", })
        vim.fn.system({ "git", "checkout", branch, })
        vim.cmd("checktime")
        vim.notify("local checkout " .. branch, vim.log.levels.INFO)
      end
    }
  })
end, { desc = "Git branches (stash & checkout)" })

-- misc pickers
map("n", "<leader>ph", function() fzf().help_tags() end, { desc = "Help tags" })
map("n", "<leader>pk", function() fzf().keymaps() end, { desc = "Keymaps" })

-- go to top of treesitter context
map("n", "[c", function()
  require("treesitter-context").go_to_context(vim.v.count1)
end, { silent = true })
