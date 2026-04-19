return {
  -- {
  --   "folke/flash.nvim",
  --   event = "VeryLazy",
  --   opts = {
  --     -- Don't override default / search — flash is opt-in via keymaps
  --     modes = {
  --       search = { enabled = false },
  --       char = { enabled = false },
  --     },
  --   },
  --   keys = {
  --     { "s", function() require("flash").jump() end,       mode = { "n", "x", "o" }, desc = "Flash jump" },
  --     { "S", function() require("flash").treesitter() end, mode = { "n", "x", "o" }, desc = "Flash treesitter" },
  --   },
  -- },

  {
    'saghen/blink.indent',
    --- @module 'blink.indent'
    --- @type blink.indent.Config
    opts = {
      blocked = {
        -- default: 'terminal', 'quickfix', 'nofile', 'prompt'
        buftypes = { include_defaults = true },
        -- default: 'lspinfo', 'packer', 'checkhealth', 'help', 'man', 'gitcommit', 'dashboard', ''
        filetypes = { include_defaults = true },
      },
      mappings = {
        -- which lines around the scope are included for 'ai': 'top', 'bottom', 'both', or 'none'
        border = 'both',
        -- set to '' to disable
        -- textobjects (e.g. `y2ii` to yank current and outer scope)
        object_scope = 'ii',
        object_scope_with_border = 'ai',
        -- motions
        goto_top = '[i',
        goto_bottom = ']i',
      },
      static = {
        enabled = true,
        char = '▎',
        whitespace_char = nil, -- inherits from `vim.opt.listchars:get().space` when `nil` (see `:h listchars`)
        priority = 1,
        -- specify multiple highlights here for rainbow-style indent guides
        -- highlights = { 'BlinkIndentRed', 'BlinkIndentOrange', 'BlinkIndentYellow', 'BlinkIndentGreen', 'BlinkIndentViolet', 'BlinkIndentCyan' },
        highlights = { 'BlinkIndent' },
      },
      scope = {
        enabled = true,
        char = '▎',
        priority = 1000,
        -- set this to a single highlight, such as 'BlinkIndent' to disable rainbow-style indent guides
        highlights = { 'BlinkIndentViolet' },
        -- optionally add: 'BlinkIndentRed', 'BlinkIndentCyan', 'BlinkIndentYellow', 'BlinkIndentGreen'
        -- highlights = { 'BlinkIndentOrange', 'BlinkIndentViolet', 'BlinkIndentBlue' },
        -- enable to show underlines on the line above the current scope
        underline = {
          enabled = false,
          -- optionally add: 'BlinkIndentRedUnderline', 'BlinkIndentCyanUnderline', 'BlinkIndentYellowUnderline', 'BlinkIndentGreenUnderline'
          -- highlights = { 'BlinkIndentOrangeUnderline', 'BlinkIndentVioletUnderline', 'BlinkIndentBlueUnderline' },
          highlights = {
            'BlinkIndentVioletUnderline'
          },
        },
      },
    },
  },

  -- {
  --   'saghen/blink.pairs',
  --   version = '*', -- (recommended) only required with prebuilt binaries
  --
  --   -- download prebuilt binaries from github releases
  --   dependencies = 'saghen/blink.download',
  --   -- OR build from source, requires nightly:
  --   -- https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
  --   -- build = 'cargo build --release',
  --   -- If you use nix, you can build from source using latest nightly rust with:
  --   -- build = 'nix run .#build-plugin',
  --
  --   --- @module 'blink.pairs'
  --   --- @type blink.pairs.Config
  --   opts = {
  --     highlights = {
  --       enabled = true,
  --       -- requires require('vim._extui').enable({}), otherwise has no effect
  --       cmdline = true,
  --       -- set to { 'BlinkPairs' } to disable rainbow highlighting
  --       groups = { 'BlinkPairsOrange', 'BlinkPairsPurple', 'BlinkPairsBlue' },
  --       unmatched_group = 'BlinkPairsUnmatched',
  --
  --       -- highlights matching pairs under the cursor
  --       matchparen = {
  --         enabled = false,
  --         -- known issue where typing won't update matchparen highlight, disabled by default
  --         cmdline = false,
  --         -- also include pairs not on top of the cursor, but surrounding the cursor
  --         include_surrounding = false,
  --         group = 'BlinkPairsMatchParen',
  --         priority = 250,
  --       },
  --     },
  --     debug = false,
  --   }
  -- },
  {
    "kylechui/nvim-surround",
    version = "*",
    event = { "BufReadPre", "BufNewFile" },
    opts = {},
  },


  {
    "saecki/live-rename.nvim",
    keys = {
      {
        "<leader>vrn",
        function()
          require("live-rename").rename({
            text = "",
            insert = true
          })
        end,
        desc = "Rename symbol (live preview)",
      },
    },
    opts = {
      -- Send a `textDocument/prepareRename` request to the server to
      -- determine the word to be renamed, can be slow on some servers.
      -- Otherwise fallback to using `<cword>`.
      prepare_rename = true,
      --- The timeout for the `textDocument/prepareRename` request and final
      --- `textDocument/rename` request when submitting.
      request_timeout = 1500,
      -- Make an initial `textDocument/rename` request to gather other
      -- occurences which are edited and use these ranges to preview.
      -- If disabled only the word under the cursor will have a preview.
      show_other_ocurrences = true,
      -- Try to infer patterns from the initial `textDocument/rename` request
      -- and use these to show hopefully better edit previews.
      use_patterns = true,
      -- The register which is used to temporarily record a macro into. This
      -- macro can then be executed on other symbols using the `macrorepeat`
      -- rename option.
      scratch_register = "l",
      keys = {
        submit = {
          { "n", "<cr>" },
          { "v", "<cr>" },
          { "i", "<C-c>" },
        },
        cancel = {
          { "n", "<esc>" },
          { "n", "q" },
          { "i", "<Esc>" },
        },
      },
      hl = {
        current = "CurSearch",
        others = "Search",
      },
    }
  },

  {
    "catgoose/nvim-colorizer.lua",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      user_default_options = {
        names = false,
        tailwind = true,
        css = true,
        mode = "background",
      },
    },
  },

  {
    "mbbill/undotree",
    keys = {
      { "<leader>u", vim.cmd.UndotreeToggle, desc = "Toggle undotree" },
    },
  },

  {
    "MagicDuck/grug-far.nvim",
    cmd = "GrugFar",
    opts = {},
    keys = {
      {
        "<leader>sr",
        function()
          require("grug-far").open()
        end,
        desc = "Search and replace"
      },
      {
        "<leader>sw",
        function()
          require("grug-far").open({ prefills = { search = vim.fn.expand("<cword>") } })
        end,
        desc = "Search/replace word under cursor"
      },
    },
  },


}
