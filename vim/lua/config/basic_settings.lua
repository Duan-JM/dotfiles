-- ===========================================================================
-- Basic Neovim options
-- ===========================================================================
local opt = vim.opt

-- ---- UI ----
opt.number         = true
opt.relativenumber = true
opt.cursorline     = true                 -- cursorcolumn intentionally off (perf)
opt.showmatch      = true
opt.matchtime      = 0
opt.signcolumn     = "yes"                -- avoid jitter when diagnostics arrive
opt.termguicolors  = true
opt.pumblend       = 10
opt.winblend       = 0
opt.pumheight      = 15
opt.cmdheight      = 1
opt.laststatus     = 3                    -- single global statusline
opt.showtabline    = 2
opt.showmode       = false
opt.ruler          = true
opt.showcmd        = true
opt.colorcolumn    = "+1"
opt.list           = true
opt.listchars      = { tab = "→ ", trail = "·", extends = "↷", precedes = "↶" }
opt.fillchars      = { vert = "│", fold = "·" }
opt.display        = "lastline"

-- ---- Search ----
opt.hlsearch   = true
opt.incsearch  = true
opt.ignorecase = true
opt.smartcase  = true

-- ---- Editing ----
opt.mouse        = "a"
opt.backspace    = { "eol", "start", "indent" }
opt.whichwrap    = "b,s,h,l,<,>,[,]"
opt.autoindent   = true
opt.smartindent  = true
opt.smarttab     = true
opt.expandtab    = true
opt.tabstop      = 4
opt.softtabstop  = 4
opt.shiftwidth   = 4
opt.textwidth    = 79
opt.virtualedit  = "onemore"
opt.scrolloff    = 3
opt.sidescrolloff = 5
opt.wrap         = false

-- ---- Files ----
opt.encoding      = "utf-8"
opt.fileencodings = "utf-8,gbk,utf-16le,cp1252,iso-8859-15,ucs-bom"
opt.fileformats   = "unix,dos,mac"
opt.autoread      = true
opt.autowrite     = true
opt.autowriteall  = true
opt.backup        = false
opt.writebackup   = false
opt.swapfile      = false
opt.hidden        = true
opt.confirm       = true
opt.switchbuf     = "useopen"
opt.modeline      = false

-- ---- Wildmenu / completion ----
opt.wildmenu     = true
opt.wildoptions  = "pum"
opt.completeopt  = { "menu", "menuone", "noselect" }
opt.shortmess:append("cs")
opt.wildignore:append({
	"*.o", "*~", "*.pyc", "*.swp", "*.bak", "*.class", "*.DS_Store",
	".git/*", ".hg/*", ".svn/*",
})

-- ---- Splits ----
opt.splitbelow = true
opt.splitright = true

-- ---- Folding ----
opt.foldmethod = "indent"
opt.foldlevel  = 99

-- ---- Timing ----
opt.timeoutlen  = 500
opt.ttimeoutlen = 50
opt.updatetime  = 300
opt.history     = 1000

-- ---- Undo ----
opt.undofile   = true
opt.undodir    = vim.fn.stdpath("state") .. "/undo"
opt.undolevels = 1000
opt.undoreload = 10000

-- ---- Misc ----
opt.errorbells  = false
opt.visualbell  = false
opt.viewoptions = { "folds", "options", "cursor", "unix", "slash" }
opt.nrformats:remove("octal")

-- ---- Dictionary (guard against missing file on minimal systems) ----
local dict = "/usr/share/dict/words"
if vim.fn.filereadable(dict) == 1 then
	opt.dictionary:append(dict)
end

-- ---- Clipboard ----
if vim.fn.has("clipboard") == 1 then
	opt.clipboard = vim.fn.has("unnamedplus") == 1 and "unnamed,unnamedplus" or "unnamed"
end

-- ---- Tags ----
opt.tags = "./tags;/," .. vim.fn.expand("~/.vimtags")

-- Append git-tracked tags file (async to avoid blocking startup).
vim.schedule(function()
	if vim.fn.executable("git") ~= 1 then return end
	vim.system({ "git", "rev-parse", "--show-toplevel" }, { text = true }, function(out)
		if out.code ~= 0 then return end
		local root = (out.stdout or ""):gsub("[\n\r]+$", "")
		if root == "" then return end
		vim.schedule(function()
			vim.opt.tags:append(root .. "/.git/tags")
		end)
	end)
end)

-- ---- Filetype / syntax ----
vim.cmd("filetype plugin indent on")
vim.cmd("syntax enable")
