return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      flavour = "mocha",
      transparent_background = true,
      float = {
        transparent = true,
        solid = false,
      },
      auto_integrations = true,
      show_end_of_buffer = true,
      term_colors = true,
      dim_inactive = { enabled = false },
      styles = {
        strings = { "bold" },
        numbers = { "bold" },
        operators = { "bold" },
        properties = { "italic" },
        functions = { "italic" },
        keywords = { "italic" },
      },
    },
    config = function(_, opts)
      require("catppuccin").setup(opts)
      vim.cmd.colorscheme("catppuccin")
    end
  },

  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    event = "VeryLazy",
    opts = {
      options = {
        icons_enabled = true,
        theme = "auto",
        component_separators = { left = "|", right = "|" },
        section_separators = { left = "", right = "" },
        globalstatus = false,
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diff", "diagnostics" },
        lualine_c = { "filename" },
        lualine_x = { "encoding", "filetype" },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
      inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = { "filename" },
        lualine_x = { "location" },
        lualine_y = {},
        lualine_z = {},
      },
    }
  },

  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      delay = 400,
      icons = {
        mappings = false
      },
    }
  },

  {
    "j-hui/fidget.nvim",
    event = "VeryLazy",
    opts = {
      notification = {
        override_vim_notify = true,
        window = {
          winblend = 0
        }
      }
    }
  },

  { "nvim-tree/nvim-web-devicons", lazy = true },
}
