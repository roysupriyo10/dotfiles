return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = ":TSUpdate",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("nvim-treesitter").setup({
        install_dir = vim.fn.stdpath("data") .. "/site"
      })

      require("nvim-treesitter").install({ "bash", "c", "cmake", "cpp", "css", "dockerfile", "go", "gomod", "gosum", "html", "javascript", "json",  "lua", "luadoc", "make", "markdown", "markdown_inline", "proto", "python", "regex", "rust", "sql", "toml", "tsx", "typescript", "vim", "vimdoc", "yaml" })
    end
  },

  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    dependencies = "nvim-treesitter/nvim-treesitter",
    event = { "BufReadPre", "BufNewFile" },
    branch = "main",
    init = function()
      vim.g.no_plugin_maps = true
    end,
    config = function()
      require("nvim-treesitter-textobjects").setup({
        select = {
          enable = true,
          lookahead = true,
          keymaps = {
            ["af"] = { query = "@function.outer", desc = "Around function" },
            ["if"] = { query = "@function.inner", desc = "Inside function" },
            ["ac"] = { query = "@class.outer", desc = "Around class" },
            ["ic"] = { query = "@class.inner", desc = "Inside class" },
            ["aa"] = { query = "@parameter.outer", desc = "Around argument" },
            ["ia"] = { query = "@parameter.inner", desc = "Inside argument" }
        }
      },
      move = {
        enable = true,
        set_jumps = true,
        goto_next_start = {
          ["]f"] = { query = "@function.outer", desc = "Next function start" },
          ["]c"] = { query = "@class.outer", desc = "Next class start" },
          ["]a"] = { query = "@parameter.inner", desc = "Next argument" },
        },
        goto_previous_start = {
          ["[f"] = { query = "@function.outer", desc = "Prev function start" },
          ["[c"] = { query = "@class.outer", desc = "Prev class start" },
          ["[a"] = { query = "@parameter.inner", desc = "Prev argument" },
        },
      },
      swap = {
        enable = true,
        swap_next = { ["<leader>sa"] = { query = "@parameter.inner", desc = "Swap with next arg" }, },
        swap_previous = { ["<leader>sA"] = { query = "@parameter.inner", desc = "Swap with prev arg" }, },
      }
    })
  end
},

{
  "nvim-treesitter/nvim-treesitter-context",
  dependencies = "nvim-treesitter/nvim-treesitter",
  event = { "BufReadPre", "BufNewFile" },
  branch = "master",
  config = function()
    require('treesitter-context').setup({
      enable = true, -- Enable this plugin (Can be enabled/disabled later via commands)
      multiwindow = false, -- Enable multiwindow support.
      max_lines = 0, -- How many lines the window should span. Values <= 0 mean no limit.
      min_window_height = 0, -- Minimum editor window height to enable context. Values <= 0 mean no limit.
      line_numbers = true,
      multiline_threshold = 20, -- Maximum number of lines to show for a single context
      trim_scope = 'outer', -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
      mode = 'cursor',  -- Line used to calculate context. Choices: 'cursor', 'topline'
      -- Separator between context and content. Should be a single character string, like '-'.
      -- When separator is set, the context will only show up when there are at least 2 lines above cursorline.
      separator = nil,
      zindex = 20, -- The Z-index of the context window
      on_attach = nil, -- (fun(buf: integer): boolean) return false to disable attaching
    })
  end
}
}
