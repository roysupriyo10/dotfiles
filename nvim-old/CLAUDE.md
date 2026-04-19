# Neovim Config

## Structure

```
nvim/
  init.lua                        -> requires "roysupriyo10"
  lua/roysupriyo10/
    init.lua                      -> boot: loads remap, lazy, setdefaults (skips lazy+setdefaults in vscode/cursor)
    lazy.lua                      -> lazy.nvim setup + inline plugin specs
    remap.lua                     -> keymaps (native nvim)
    vscode_remap.lua              -> keymaps (vscode/cursor extension)
    setdefaults.lua               -> vim options + format-on-save autocommands
    lsp/
      lspconfig.lua               -> all LSP server configs (lazy plugin spec)
      mason.lua                   -> mason installer config (lazy plugin spec)
  after/plugin/
    colors.lua                    -> colorscheme (catppuccin-mocha)
    telescope.lua                 -> telescope setup + keymaps + claude file picker
    treesitter.lua                -> treesitter config
    fugitive.lua                  -> git fugitive keymap
    undotree.lua                  -> undotree keymap
    cmp.lua                       -> empty (completion configured inline in lazy.lua)
    nx.lua                        -> commented out
```

## Plugin Manager

lazy.nvim. Plugins defined in two places:
- Inline in `lua/roysupriyo10/lazy.lua` (lines 18-264)
- Imported from `roysupriyo10.lsp` module (line 266)

## LSP

### Mason (`lsp/mason.lua`)
Auto-installs: clangd, pyright, gopls, html, ts_ls, cssls, jdtls, tailwindcss, emmet_language_server, lua_ls, eslint, jsonls, yamlls, bashls, dockerls, rust_analyzer

### Server Configs (`lsp/lspconfig.lua`)
- Shared `on_attach` (lines 17-70): keybinds for refs, definitions, rename, diagnostics, etc. via telescope
- Shared `capabilities` from cmp-nvim-lsp (line 72)
- **clangd** (lines 88-98): default setup, filetypes: c, cpp, objc, objcpp, cuda (excludes proto)
- **buf_ls** (line 80): proto only
- **ts_ls** (lines 115-127): root_dir = `.git`
- **eslint** (lines 178-192): experimental unstable_config_lookup_from_file
- **cssls**: ignores unknownAtRules
- **lua_ls**: globals = { "vim" }, workspace includes VIMRUNTIME
- **jsonls/yamlls**: schema store configs for common config files

## Formatting

### No formatting plugins installed
No conform.nvim, null-ls, formatter.nvim, or similar.

### Format-on-save autocommands (`setdefaults.lua:37-60`)
| Augroup    | Event         | Patterns                                            | Tool      | Method                    |
|------------|---------------|-----------------------------------------------------|-----------|---------------------------|
| Prettier   | BufWritePost  | js, ts, jsx, tsx, vue, html, css, scss, less, json, md | prettier  | buffer filter (`%!prettier`) |
| pyformat   | BufWritePost  | py                                                  | black     | shell cmd (`!black`)      |

Both use BufWritePost (format lands in buffer after write, not saved to disk in same operation). Both preserve cursor position.

### No C/C++ format-on-save exists

### Manual format keymaps (`remap.lua`)
- `<leader>ff` (line 32): `vim.lsp.buf.format` -- works for any LSP with formatting (including clangd)
- `<leader>gp` (line 7): prettier via stdin
- `<leader>ef` (line 39): eslint_d fix-to-stdout

## Key Settings (`setdefaults.lua`)
- leader: space
- tabs: 2 spaces (tabstop=2, shiftwidth=2, expandtab)
- line numbers: absolute + relative
- no swap/backup, persistent undo (~/.vim/undodir)
- no hlsearch, incremental search, case insensitive
- scrolloff=8, colorcolumn=80, cursorline
- termguicolors enabled

## Key Plugins
- **snacks.nvim**: bigfile, indent, image
- **supermaven-nvim**: AI completion
- **codeium.nvim**: AI completion (both active in cmp sources)
- **nvim-cmp**: completion engine (C-y confirm, C-j/k nav, C-l/h snippet jump)
- **telescope**: file finding, grep, LSP navigation
- **lualine**: statusline
- **which-key**: key hint popup (timeoutlen=750)
- **nvim-comment**: gcc/gc commenting
- **nvim-colorizer**: color preview (tailwind enabled)
- **catppuccin**: theme (transparent bg)
- **treesitter**: syntax highlighting (auto_install=true)

## Telescope Keymaps (`after/plugin/telescope.lua`)
- `<leader>pf`: find_files
- `<leader>rf`: oldfiles
- `<C-p>`: git_files
- `<leader>fc`: grep_string (word under cursor)
- `<leader>pa`: live_grep
- `<leader>pb`: buffers (sort by last used)
- `<leader>ps`: live_grep sorted by modified
- `<leader>fe`: find by extension (prompts for ext)
- `<leader>pw`: grep string (prompts for input)
- `<leader>cf` / `<C-f>` (insert): claude file picker (inserts absolute path)

## Existing Format-on-Save Pattern
The established pattern in `setdefaults.lua` uses:
1. `create_augroup` with `{ clear = true }`
2. `BufWritePost` event
3. Save/restore cursor with `nvim_win_get_cursor`/`nvim_win_set_cursor`
4. External tool via `vim.cmd("silent!...")`
