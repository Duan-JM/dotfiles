Vim Configuration
=====================
## Intro

这个 VIM 的安装与配置是我个人当前的主力代码开发的工具。日常使用 VIM 结合 TMUX 一起开发，这里总结了 VIM 的安装与配置。

## NeoVim 安装与配置

我最开始的时候使用的是 Vim 而不是 NeoVim 并且一定程度上在两者之间还没有特别笃定的选择。所以当前的配置是同时支持 NeoVim 和 Vim 的。当前安装脚本只支持 ubuntu 和 MacOS

```bash
# 找到仓库中 vim 文件夹下的 install.sh
bash ./install.sh sudo # 加 sudo 就是使用 sudo 权限安装
```

由于这个脚本主要为我个人使用，可能会出现安装不完整的情况。如果允许的话，可以自行查看下 install.sh 脚本，没有什么复杂逻辑很简单的。执行完成后可以手动检查：
- `~/.config/nvim` 是否软链接到 `~/.vim`。
- ctags 是否安装。
- 运行启动 `vim` 后看是否有报错。


## Mappings
```bash
" Caution: Mapping should place before PluginConfigure
let mapleader=' '

nmap . .`[
nmap <leader>w :w<CR>


nnoremap <Leader>eg :e ++enc=gbk<CR>
nnoremap <Leader>eu :e ++enc=utf8<CR>
nnoremap <Leader>xd :%!xxd<CR>
nnoremap <Leader>xr :%!xxd -r<CR>                       " show HEX and return

" nnoremap <leader>sl :set list!<CR>                    " quick config to see or not see special character  
nnoremap <leader>ll :set conceallevel=0<CR>             " quick change conceal mode

nnoremap <leader>ev :tabe $MYVIMRC<CR>                  " Quickly edit/reload the vimrc file


" Window control
nnoremap <leader>t :tabe<CR>                            " open a new tab
nnoremap <leader>v :vnew<CR>                            " close tab
nnoremap <leader>tq :tabclose<CR>
nnoremap <leader>tn :tabnext<CR>

" use ]+space create spaceline
nnoremap [<space>  :<c-u>put! =repeat(nr2char(10), v:count1)<cr>'[
nnoremap ]<space>  :<c-u>put =repeat(nr2char(10), v:count1)<cr>


" Use <C-L> to clear the highlighting of :set hlsearch
if maparg('<C-L>', 'n') ==# ''
    nnoremap <silent> <C-L> :nohlsearch<C-R>=has('diff')?'<Bar>diffupdate':''<CR><CR><C-L>
endif

" map g* to *
nnoremap j gj
nnoremap k gk

" use <C-l> to correct spell while insert mode
inoremap <C-l> <c-g>u<Esc>[s1z=`]a<c-g>u
```

PluginList
---------
```bash
call plug#begin('~/.vim/plugged')
" Need attention
Plug 'APZelos/blamer.nvim'
let g:blamer_enabled = 1           " auto enable
let g:blamer_show_in_visual_modes = 0
Plug 'sainnhe/edge'



" System
Plug 'vim-scripts/LargeFile'                            " Fast Load for Large files
Plug 'michaeljsmith/vim-indent-object'                  " used for align
Plug 'terryma/vim-smooth-scroll'                        " smooth scroll
Plug 'wellle/targets.vim'                               " text objects
Plug 'ryanoasis/vim-devicons'                           " extensions for icons
Plug 'brglng/vim-im-select'                             " auto change input methods, needs `imselect` cmd
Plug 'unblevable/quick-scope'                           " Advance setting for f t search
Plug 'mbbill/undotree'                                  " history of the undo

if has('nvim')
  Plug 'ncm2/float-preview.nvim'                              " showing doc with float windows not preview beside the functions
  let g:float_preview#docked = 0
endif
Plug 'voldikss/vim-floaterm'                                  " floating terminaler you must like it

" Coding
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'dense-analysis/ale', {'for': ['cpp', 'python']}   " Syntax Check
Plug 'SirVer/ultisnips'                                 " snippets
Plug 'Duan-JM/vdeamov-snippets'
Plug 'tpope/vim-commentary'
Plug 'Raimondi/delimitMate'                             " Brackets Jump 智能补全括号和跳转
                                                        " 补全括号 shift+tab出来
Plug 'vim-scripts/matchit.zip'                          " %  g% [% ]% a%
Plug 'andymass/vim-matchup'                             " extence
Plug 'octol/vim-cpp-enhanced-highlight', {'for':['c', 'cpp']}
Plug 'godlygeek/tabular'                                " align text
Plug 'tpope/vim-surround'                               " change surroundings
                                                        " c[ange]s[old parttern] [new partten]
                                                        " ds[partten]
                                                        " ys(iww)[partten] / yss)
Plug 'tpope/vim-repeat'                                 " for use . to repeat for surround
Plug 'liuchengxu/vista.vim', {'for':['c', 'cpp', 'python', 'markdown']}         " show params and functions

Plug 'skywind3000/asyncrun.vim'
Plug 'skywind3000/asynctasks.vim'  " This combination can change default run


" Writing Blog
Plug 'godlygeek/tabular', {'for': ['markdown']}
Plug 'plasticboy/vim-markdown', {'for': ['markdown']}
Plug 'iamcco/markdown-preview.nvim', { 'do': { -> mkdp#util#install() }, 'for': ['markdown', 'vim-plug']}
Plug 'mzlogin/vim-markdown-toc', {'for': ['markdown']}
" :GenTocGFM/:GenTocRedcarpet
":UpdateToc 更新目录
Plug 'dhruvasagar/vim-table-mode', {'for': ['markdown']}
"<leader>tm to enable
"|| in the insert mode to create a horizontal line
"| match the | up row
"<leader>tdd to delete the row
"<leader>tdc to delete the coloum
"<leader>tt to change the exist text to format table
Plug 'xuhdev/vim-latex-live-preview', {'for': ['tex']}                          " Use when you work with cn
Plug 'lervag/vimtex', {'for': ['tex']}                                          " English is okay, fail with cn


"FileManage
Plug 'scrooloose/nerdtree'
Plug 'Xuyuanp/nerdtree-git-Plugin'
Plug 'tiagofumo/vim-nerdtree-syntax-highlight'
Plug 'mhinz/vim-startify'
Plug 'justinmk/vim-dirvish'
Plug 'kristijanhusak/vim-dirvish-git'


" Appearance
Plug 'itchyny/lightline.vim'
Plug 'maximbaz/lightline-ale'
Plug 'flazz/vim-colorschemes'
Plug 'Yggdroot/indentLine'                                                      " Show indent line
Plug 'kshenoy/vim-signature'                                                    " Visible Mark
Plug 'luochen1990/rainbow'                                                      " multi color for Parentheses

" Github
Plug 'mattn/gist-vim'                                                           " :Gist -l/-ls :Gist -e (add gist name) -s (add description) -d (delete)
Plug 'mattn/webapi-vim'
Plug 'tpope/vim-fugitive'
Plug 'junegunn/gv.vim'                                                          " Rely on fugitive

" Search
Plug 'Yggdroot/LeaderF'                                                         " Ultra search tools
                                                                                " <c-]> open in vertical 
Plug 'junegunn/vim-slash'                                                       " clean hightline after search
call plug#end()
```
