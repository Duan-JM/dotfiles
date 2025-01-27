-- 基础设置
vim.o.compatible = false -- 不兼容 Vi
vim.o.spell = false -- 禁用拼写检查
vim.o.number = true -- 显示行号
vim.o.relativenumber = true -- 显示相对行号
vim.o.hlsearch = true -- 高亮匹配
vim.o.incsearch = true -- 输入时显示匹配
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.matchtime = 0
vim.o.showmatch = true -- 高亮匹配括号
vim.o.encoding = "utf-8"
vim.o.fileencodings = "utf-8,gbk,utf-16le,cp1252,iso-8859-15,ucs-bom"
vim.o.fileformats = "unix,dos,mac"
vim.o.linespace = 0 -- 行距为0
vim.o.confirm = true -- 退出前确认
vim.o.backup = false
vim.o.writebackup = false
vim.o.swapfile = false
vim.o.lazyredraw = true -- 执行宏时不刷新界面
vim.o.backspace = "eol,start,indent" -- 删除换行
vim.o.ruler = true -- 显示光标位置
vim.o.modeline = false -- 禁用 modeline
vim.o.showmode = false -- 不显示模式
vim.o.mouse = "a" -- 启用鼠标
vim.o.autoindent = true -- 自动缩进
vim.o.smartindent = true
vim.o.cindent = true
vim.o.smarttab = true
vim.o.copyindent = true
vim.o.tabstop = 4
vim.o.softtabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true
vim.o.textwidth = 79
vim.o.history = 1000
vim.o.timeoutlen = 500
vim.o.list = true -- 显示特殊字符
vim.o.autoread = true
vim.o.autowrite = true
vim.o.autowriteall = true
vim.cmd("set iskeyword-=_,.,=,-,:,")
vim.o.switchbuf = "useopen" -- 使用已打开的缓冲区
vim.o.wildmenu = true
vim.o.cursorcolumn = true -- 高亮光标列
vim.o.cursorline = true -- 高亮光标行

-- 配置 Neovim 特性
if vim.fn.has("nvim") == 1 then
	vim.o.wildoptions = "pum"
	vim.o.termguicolors = true -- 启用真彩色
	vim.o.pumblend = 30 -- 浮动窗口透明度
	vim.o.winblend = 9
else
	vim.o.wildmode = "list:longest,full"
end

-- 更多设置
vim.cmd("set nowrap")
vim.o.whichwrap = "b,s,h,l,<,>,>h,[,]"
vim.cmd("set t_Co=256")
vim.o.laststatus = 2 -- 总是显示状态栏
vim.o.showtabline = 2 -- 总是显示标签栏
vim.o.cmdheight = 2
vim.o.hidden = true
vim.o.display = "lastline"
vim.o.errorbells = false
vim.o.visualbell = false
vim.o.showcmd = true -- 显示部分命令
vim.o.viewoptions = "folds,options,cursor,unix,slash"
vim.o.virtualedit = "onemore"
vim.o.completeopt = "menu,menuone,longest"
vim.o.complete = ".,w,b,u,t"
vim.o.tags = "./tags;/,~/.vimtags"
vim.o.dictionary = "/usr/share/dict/words,~/.vim/dict/"
vim.o.shortmess = vim.o.shortmess .. "cs"
vim.o.undofile = true -- 启用撤销文件
vim.o.undodir = vim.fn.expand("$HOME/.vim/undo")
vim.o.undolevels = 1000
vim.o.undoreload = 10000
vim.o.splitbelow = true
vim.o.splitright = true
vim.o.updatetime = 300
vim.o.ttimeout = true
vim.o.ttimeoutlen = 50
vim.o.nrformats = vim.o.nrformats:gsub("octal", "")
vim.o.listchars = "tab:→\\ ,trail:·,extends:↷,precedes:↶"
vim.o.fillchars = "vert:│,fold:·"
vim.o.pumheight = 15

-- 文件类型与语法高亮
vim.cmd("filetype plugin indent on")
vim.cmd("syntax enable")

-- 剪贴板设置
if vim.fn.has("clipboard") == 1 then
	if vim.fn.has("unnamedplus") == 1 then
		vim.o.clipboard = "unnamed,unnamedplus"
	else
		vim.o.clipboard = "unnamed"
	end
end

-- 忽略文件
vim.o.wildignore = "*.o,*~,*.pyc,*.swp,*.bak,*.class,*.DS_Store"
if vim.fn.has("win16") == 1 or vim.fn.has("win32") == 1 then
	vim.o.wildignore = vim.o.wildignore .. ",*/.git/*,*/.hg/*,*/.svn/*,*/.DS_Store"
else
	vim.o.wildignore = vim.o.wildignore .. ".git\\*,.hg\\*,.svn\\*"
end

vim.o.scrolloff = vim.o.scrolloff == 0 and 1 or vim.o.scrolloff
vim.o.sidescrolloff = vim.o.sidescrolloff == 0 and 5 or vim.o.sidescrolloff
vim.o.colorcolumn = "+1"

-- 折叠设置
vim.o.foldmethod = "indent"
vim.o.foldlevel = 99

-- Git tags 设置
local gitroot = vim.fn.substitute(vim.fn.system("git rev-parse --show-toplevel"), "[\n\r]", "", "g")
if gitroot ~= "" then
	vim.o.tags = vim.o.tags .. "," .. gitroot .. "/.git/tags"
end

print("Neovim settings loaded!")
