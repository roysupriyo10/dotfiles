local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath
  })
end
vim.opt.rtp:prepend(lazypath)

local specs = { { import = "plugin" } }

-- fetch current user for loading specific plugins
local username = os.getenv("USER")
if not username then
  error("$USER environment variable is not set")
end

local user_plugins_path = vim.fn.stdpath("config") .. "/lua/profiles/" .. username .. "/plugins"
if vim.fn.isdirectory(user_plugins_path) == 1 then
  specs[#specs + 1] = {
    import = "profiles." .. username .. ".plugins"
  }
end

require("lazy").setup(specs, {
  checker = {
    enabled = true,
    notify = false
  },
  change_detection = {
    notify = false
  },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "matchit",
        "matchparen",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin"
      }
    }
  }
})
