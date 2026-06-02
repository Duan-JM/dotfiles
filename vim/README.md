# Neovim Configuration

A Lua-based Neovim configuration managed by [lazy.nvim](https://github.com/folke/lazy.nvim).

## Install

```bash
bash ./install.sh           # macOS (uses brew) or Ubuntu (uses apt+sudo)
bash ./install.sh ""        # disable sudo prefix when running as root
```

The script:

1. Installs Neovim, Node, git, ripgrep, fd, universal-ctags, python3 + pynvim, and
   formatters (prettier / isort / stylua / black / google-java-format).
2. Backs up any existing `~/.vim`, `~/.vimrc`, `~/.config/nvim` with a
   timestamp suffix.
3. **Symlinks** this directory to `~/.config/nvim` (so future `git pull`s take
   effect immediately — no re-running the script).

On first `nvim` launch, lazy.nvim will clone and set up every plugin.

## Layout

```
init.lua
├── lua/config/
│   ├── lazy.lua            lazy.nvim bootstrap + leader keys
│   ├── basic_settings.lua  vim options
│   ├── addon_filetypes.lua filetype detection (vim.filetype.add)
│   ├── autocmds.lua        autocommands (augroup-isolated)
│   ├── mappings.lua        global keymaps (vim.keymap.set)
│   └── functions.lua       custom commands / tabline / helpers
└── lua/plugins/
    ├── colorscheme.lua     sainnhe/edge
    ├── editor.lua          surround, commentary, repeat, undotree,
    │                       quick-scope, nvim-autopairs, neo-tree
    ├── ui.lua              lualine, rainbow-delimiters, web-devicons
    ├── treesitter.lua      nvim-treesitter (+ textobjects, autotag)
    ├── coding.lua          aerial.nvim (outline)
    ├── git.lua             gitsigns + vim-fugitive
    ├── telescope.lua       fuzzy finder
    ├── formatting.lua      conform.nvim (format-on-save)
    └── lsp/init.lua        mason + nvim-lspconfig + nvim-cmp + LuaSnip + jdtls
```

## Key Bindings

Leader = `<space>`.

### General

| Keys             | Action                                            |
|------------------|---------------------------------------------------|
| `<leader>w`      | Save buffer                                       |
| `<leader>ev`     | Edit `$MYVIMRC` in a new tab                      |
| `<leader>t / v`  | New tab / new vertical split                      |
| `<leader>tq / tn`| Close tab / next tab                              |
| `[<space>` / `]<space>` | Insert blank line above / below (count-aware) |
| `<C-l>`          | Clear search highlight + redraw                   |
| `j` / `k`        | Display-line aware when no count (5j is unchanged)|
| `&`              | Repeat last `:s` with flags                       |

### Find / search (telescope)

| Keys         | Action                                  |
|--------------|-----------------------------------------|
| `<C-p>`      | Find files                              |
| `<leader>ff` | Find files                              |
| `<leader>fg` | Live grep                               |
| `<leader>fb` | Buffer list                             |
| `<leader>fl` | Fuzzy lines in current buffer           |
| `<leader>ft` | Treesitter symbols                      |
| `<leader>fh` | Help tags                               |
| `<leader>fr` | Recent files                            |

Inside Telescope: `<C-j/k>` next/prev, `<C-]>` open in tab, `<C-x/v>` h/v split.

### Files / outline / undo

| Keys         | Action                                  |
|--------------|-----------------------------------------|
| `<leader>nt` | Open Neo-tree on left, reveal file      |
| `<leader>o`  | Toggle Aerial outline (replaces Vista)  |
| `<leader>u`  | Toggle undotree                         |

### LSP (set on `LspAttach`)

| Keys         | Action                                  |
|--------------|-----------------------------------------|
| `gd / gD`    | Goto definition / declaration           |
| `gr / gi`    | References / implementation             |
| `K`          | Hover                                   |
| `<leader>rn` | Rename                                  |
| `<leader>ca` | Code action                             |
| `[d` / `]d`  | Previous / next diagnostic              |

### Git

| Keys         | Action                                  |
|--------------|-----------------------------------------|
| `<leader>gs` | `:Git` status                           |
| `<leader>gd` | `:Gdiffsplit`                           |
| `<leader>gb` | `:Git blame`                            |
| `]c` / `[c`  | Next / previous hunk (gitsigns)         |
| `<leader>hs/hr/hp/hb` | Stage/reset/preview/blame hunk |

### Insert mode

| Keys           | Action                                          |
|----------------|-------------------------------------------------|
| `<C-Space>`    | Trigger completion                              |
| `<C-d>`/`<C-f>`| Scroll docs in completion popup                 |
| `<C-l>`        | Auto-fix previous spelling error                |
| `<C-x><C-l>`   | Native line completion                          |
| `<C-x><C-f>`   | Native filename completion                      |

## Useful commands

```
:Mason                       Manage LSPs / formatters
:Telescope                   List all telescope pickers
:Neotree                     File explorer
:AerialToggle                Symbol outline
:Rename {newname}            Rename current file on disk
:Stab                        Prompt for tab width (sets ts/sts/sw)
:PyrightSetPoetrySetup       Point pyright at the current poetry venv
:Gdiffsplit                  Diff against index
:Git blame                   Blame current file
```

## Debugging Neovim startup

```bash
# Startup time profile
nvim --startuptime /tmp/nvim-startup.log +qa && less /tmp/nvim-startup.log

# Verbose runtime log
nvim -V13/tmp/nvim-verbose.log <file>

# Health check
nvim +checkhealth
```

## References
- [lazy.nvim docs](https://lazy.folke.io/)
- [Is there a "vim runtime log"?](https://stackoverflow.com/questions/3025615/is-there-a-vim-runtime-log)
- [如何调试 Vim 脚本 | Harttle Land](https://harttle.land/2018/12/05/vim-debug.html)
