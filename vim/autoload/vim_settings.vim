" ======================
" Set basic vim settings
" ======================
set nocompatible                                                        " not compatible for vi
set nospell                                                             " close spell examine
set number                                                              " show number
set relativenumber                                                      "show relative line number
set hlsearch                                                            " Highlight the matching part
set incsearch                                                           " Shows the match while typing
set ignorecase
set smartcase
set matchtime=0
set showmatch                                                           " Show matching brackets/parenthesis
set encoding=utf-8                                                      " configure the encoding
set fileencodings=utf-8,gbk,utf-16le,cp1252,iso-8859-15,ucs-bom
set fileformats=unix,dos,mac
set linespace=0                                                         " No extra spaces between rows
set confirm                                                             " Confirm before vim exit
set nobackup
set nowritebackup
set noswapfile
set lazyredraw                                                          " don't update the display while executing macros
set backspace=eol,start,indent                                          " use backspace for delete space line
set ruler                                                               " show the cursor's position
set nomodeline                                                          " disable mode lines (security measure)
set noshowmode                                                          " do not show Insert, We already have it in lightline
set mouse=a                                                             " allow mouse select and etc operation
set autoindent                                                          " config the indent
set smartindent
set cindent
set smarttab
set copyindent
set tabstop=2  softtabstop=2 shiftwidth=2 expandtab textwidth=79
set history=1000                                                        " save 1000 cmd
set timeoutlen=500                                                      " give u 500 time to react for cmd
set list                                                                " show the special character
set autoread
set autowrite
set autowriteall                                                        " Auto-write all file changes
set iskeyword-=_,.,=,-,:,
set switchbuf=useopen                                                   " reveal already opened files from the quickfix window instead of opening new buffers
set wildmenu
set cursorcolumn                                                        " highlight column
set cursorline                                                          " highlight row
if has('nvim')                                                          " Use floating windows to complete the commond, only neovim support
  set wildoptions=pum
  set termguicolors                                                     " With out this settings, transparable float-win will not work normally
  set pumblend=30                                                       " Let floatingwindow to be transparable
  set winblend=9
else
  set wildmode=list:longest,full                                        " Set list to show completeopt, however it will lead to disfunc for floating windows
endif
set nowrap                                                              " Do not wrap long lines
set whichwrap=b,s,h,l,<,>,>h,[,]                                        " Backspace and cursor keys wrap too
set t_Co=256                                                            " number of colors
"set autochdir                                                          "disable for leadf
set laststatus=2                                                        " always show statusline
set showtabline=2                                                       " always show tabline
set cmdheight=2
set hidden
set display+=lastline
set noerrorbells novisualbell t_vb=                                     " cancel the annoying bell
set belloff=all
set showcmd                                                             " Show partial commands in status line and
" Selected characters/lines in visual mode
set viewoptions=folds,options,cursor,unix,slash                         " Better Unix / Windows compatibility
set virtualedit=onemore                                                 " used with caution of breaking plugins

set completeopt=menu,menuone,longest
set complete=.,w,b,u,t
set tags=./tags;/,~/.vimtags
set dictionary+=/usr/share/dict/words                                   " autocompletion with dictionary help
set dictionary+=~/.vim/dict/
set statusline+=%*
set statusline+=%#warningmsg#
if has('patch-7.4.314')
  " don't give ins-completion-menu messages.
  set shortmess+=c
endif
set shortmess+=s

set undofile                                                            " enable undo after close the file
set undodir=$HOME/.vim/undo
set undolevels=1000
set undoreload=10000

set splitbelow
set splitright

set updatetime=300                                                      " setup according to coc.nvim example

set ttimeout                                                            " from SpaceVim
set ttimeoutlen=50
set nrformats-=octal
set listchars=tab:→\ ,trail:·,extends:↷,precedes:↶
set fillchars=vert:│,fold:·
set pumheight=15

filetype on
filetype plugin indent on

" Always show the signcolumn, otherwise it would shift the text each time
" diagnostics appear/become resolved.
if has("patch-8.1.1564")
  " Recently vim can merge signcolumn and number column into one
  set signcolumn=number
else
  set signcolumn=yes
endif

if has('syntax')
    syntax enable
endif

if has('clipboard')
    if has('unnamedplus')                                               " When possible use + register for copy-paste
        set clipboard=unnamed,unnamedplus
    else                                                                " On mac and Windows, use * register for copy-paste
        set clipboard=unnamed
    endif
endif


set wildignore=*.o,*~,*.pyc,*.swp,*.bak,*.class,*.DS_Store              " vim will ignore them
if has('win16') || has('win32')
    set wildignore+=*/.git/*,*/.hg/*,*/.svn/*,*/.DS_Store
else
    set wildignore+=.git\*,.hg\*,.svn\*
endif

if !&scrolloff                                                          " Minimum lines to keep above and below cursor
    set scrolloff=1
endif

if !&sidescrolloff
    set scrolloff=5
endif


set colorcolumn=+1                                                      " color the 81 column for warning
" let &colorcolumn=join(range(81,999),',')
" let &colorcolumn='80,'.join(range(120,999),',')

" fold config
" foldmethod [diff, expr, indent, manual, marker, syntax]
" diff show the diff between unfold and fold
" expr use `foldexpr` to config fold logic
" indent fold base on indent
" manual use zf zF or :Fold to fold, zfa(,
"                     :mkview to save
"                     :loadview to reload
" mark ....
" syntax
set foldmethod=indent
set foldlevel=99

let gitroot = substitute(system('git rev-parse --show-toplevel'),'[\n\r]', '', 'g')                          " Make tags placed in .git/tags file available in all levels of a repository
if gitroot != ''
    let &tags = &tags . ',' . gitroot . '/.git/tags'
endif

" set colorful cursors
" set guicursor=n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50
"   \,a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor
"   \,sm:block-blinkwait175-blinkoff150-blinkon175

" wrap config (not recommend
" formation options
" default is tcq
" t: 根据 textwidth 自动折行
" c: 在（程序源代码中的）注释中自动折行，插入合适的注释起始字符
" r: 插入模式下在注释中键入回车时，插入合适的注释起始字符
" q: 允许使用"gq"命令对注释进行格式化；
" n: 识别编号列表，编号行的下一行的缩进由数字后的空白决定（与“2”冲突，需要“autoindent”）；
" 2: 使用一段的第二行的缩进来格式化文本；
" l: 在当前行长度超过 textwidth 时，不自动重新格式化；
" m: 在多字节字符处可以折行，对中文特别有效（否则只在空白字符处折行）；
" M: 在拼接两行时（重新格式化，或者是手工使用“J”命令），如果前一行的结尾或后一行的开头是多字节字符，则不插入空格，非常适合中文
"
" set textwidth=80 "最大字符长度
" set formatoptions+=t
set formatoptions-=t "disable wrap
" set formatoptions-=l " wrap long lines
" if v:version > 703 || v:version == 703 && has('patch541')
"     set formatoptions+=j " Delete comment chars when join comment lines
" endif
" set wrapmargin=2 " 2 chars wrap margin from the right window border, hard wrap


func! vim_settings#init_settings()
  echom "custom vim settings activated"
endfunc
