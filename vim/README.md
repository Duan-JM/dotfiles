Welcome to MyVimrc
==================
TODO LIST
--------
- [x] Try coc plugin to replce YCM or something else

Special Information
------------------
After use neovim for some time, I found neovim is a bit faster than vim, and it 
support floating window in verison 0.4. So literally, I directly use my vim configure
for neovim, it works fine.

**ps:** if you DO NOT want use vim config in neovim, just ignore the `ln` command while installing

### NeoVim Installation & vimrc
```Bash
# for mac
brew install neovim
# `brew install --HEAD neovim` for latest version
pip3 install pynvim
ln -sf ~/.vim ~/.config/nvim
ln -sf ~/.vimrc ~/.config/nvim/init.vim

# for ubuntu

sudo apt-add-repository ppa:neovim-ppa/stable
# if you want to install latest version change `stable` to `unstable`
sudo apt update
sudo apt-get install neovim
pip3 install pynvim
ln -sf ~/.vim ~/.config/nvim
ln -sf ~/.vimrc ~/.config/nvim/init.vim

# It is optional to change zsh alias to use vim as nvim
# put code below in the ~/.zshrc
alias vim='nvim'
alias vi='nvim'
```


Vim Installation
----------------
### For Mac
```bash
brew install vim --with-lua --with-python
brew install vim # in new version of brew
```
### For Ubuntu
1. Install for Prerequisites
```bash
sudo apt-get install liblua5.1-dev \
                     luajit libluajit-5.1 \
                     python-dev ruby-dev\
                     libperl-dev libncurses5-dev\
                     libatk1.0-dev libx11-dev\
                     libxpm-dev libxt-dev
sudo mkdir /usr/include/lua5.1/include
sudo cp /usr/include/lua5.1/*.h /usr/include/lua5.1/include/
```
2. Download VIM from github
```bash
git clone https://github.com/vim/vim ~/vim
cd ~/vim
git pull && git fetch
cd ~/vim/src
make distclean
./configure --with-features=huge \
            --enable-rubyinterp \
            --enable-largefile \
            --disable-netbeans \
            --enable-pythoninterp \
            --enable-perlinterp \
            --enable-luainterp \
            --with-luajit \
            --enable-fail-if-missing \
            --enable-cscope
make
sudo make install
```
3. Check VIM
```bash
vim --version
# check if there is + in front of the lua and python
```
PluginInstall
------------
1. Git from this repository
```bash
git clone https://github.com/VDeamoV/VDeamoV-vimrc.git ~/.vim
cd ~/.vim
git clone https://github.com/powerline/fonts.git ~/.vim/fonts
cd ~/.vim/fonts
sudo ./install.sh # install fonts for the themes
cp ~/.vim/vimrc ~/.vimrc
```
2. Install Plugs
  - Check requirements
    ```bash
    brew install node
    brew install cquery
    npm install cnpm -g --registry=https://registry.npm.taobao.org
    cnpm -g install yarn # apt-get install yarn will not work
    yarn config set registry 'https://registry.npm.taobao.org'
    pip3 install autopep8
    pip3 install pylint
    pip3 install jedi
    ```

  - After enter the vim, use the commond below
    ```bash
    :PlugInstall
    ```

  - coc for snippets
    ```bash
    :CocInstall coc-ultisnips
    ```

  - coc-python for python code complete
    ```bash
    :CocInstall coc-python
    ```

  - coc-java for java code complete
    ```bash
    :CocInstall coc-java
    ```
    For in China, download jdt.ls directly in plugin will be extremely slow.
    Try download in the offical website [here](http://download.eclipse.org/jdtls/milestones/?d), then place them in the path
    `~/.config/coc/extension/coc-java-data/server`

  - Configure for YCM (optional try coc.nvim instead)
    ```bash
    cd ~/.vim/plugged/YouCompleteMe/
    git submodule update --init --recursive
    sudo ./install.py -all
    ```


Need Additional Configure
------------------------
1. Startify
- *You need to modify the startify configure in the vimrc*

2. ColorScheme
- *Search colorscheme in the vimrc to find my configure*
- *use `:colorscheme` then tab to see other scheme*
- *`<leader>bg` to change the daymode and nightmode*

3. ale
- *You need to ensure you have install the correct lint which you used in the config, such as pylint, autopep8*

4. Utlisnip
- *Search python to find all the configure for python path, change it to your python path*
- *Utlisnip with coc*, install extension with cmd `:CocInstall coc-ultisnips`

5. ACK
- Need to install [the_silver_searcher](https://github.com/ggreer/the_silver_searcher) manually 

Mappings
--------
```bash
let mapleader=' '

nmap . .`[

nnoremap <Leader>eg :e ++enc=gbk<CR>
nnoremap <Leader>eu :e ++enc=utf8<CR>

nnoremap <leader>l :set list!<CR>                       " quick config to see or not see special character  
nnoremap <leader>ll :set conceallevel=0<CR>             " quick change conceal mode
nnoremap <leader>lc :set conceallevel=1<CR>

nnoremap <leader>ev :tabe $MYVIMRC<CR>                  " Quickly edit/reload the vimrc file

" show HEX and return
nnoremap <Leader>xd :%!xxd<CR>
nnoremap <Leader>xr :%!xxd -r<CR>

" Window control
nnoremap <leader>t :tabe<CR>                            " open a new tab
nnoremap <leader>v :vnew<CR>                            " close tab
nnoremap <leader>tq :tabclose<CR>

" use ]+space create spaceline
nnoremap [<space>  :<c-u>put! =repeat(nr2char(10), v:count1)<cr>'[

" Use <C-L> to clear the highlighting of :set hlsearch
if maparg('<C-L>', 'n') ==# ''
    nnoremap <silent> <C-L> :nohlsearch<C-R>=has('diff')?'<Bar>diffupdate':''<CR><CR><C-L>
endif
```

PluginList
---------
```bash
" Need attention
Plug 'takac/vim-hardtime'

" System
Plug 'lyokha/vim-xkbswitch', {'as': 'xkbswitch'}        " fix for cn change en
Plug 'vim-scripts/LargeFile'                            " Fast Load for Large files
Plug 'kana/vim-textobj-indent'
Plug 'kana/vim-textobj-user'
Plug 'kana/vim-textobj-syntax'
Plug 'kana/vim-textobj-function', { 'for':['c', 'cpp', 'vim', 'java', 'python'] }
Plug 'sgur/vim-textobj-parameter'
Plug 'michaeljsmith/vim-indent-object'                  " used for align
Plug 'terryma/vim-smooth-scroll'                        " smooth scroll

" Coding
Plug 'neoclide/coc.nvim', {'tag': '*', 'do': './install.sh'}
Plug 'ludovicchabant/vim-gutentags'                     " auto generate tags
Plug 'w0rp/ale'                                         " Syntax Check
Plug 'SirVer/ultisnips'                                 " snippets
Plug 'VDeamoV/vim-snippets'
Plug 'tpope/vim-commentary'
Plug 'Raimondi/delimitMate'                             " Brackets Jump 智能补全括号和跳转
                                                        " 补全括号 shift+tab出来
Plug 'vim-scripts/matchit.zip'                          " %  g% [% ]% a%
Plug 'Shougo/echodoc.vim'                               " U will like it
Plug 'octol/vim-cpp-enhanced-highlight', {'for':['c', 'cpp']}
Plug 'easymotion/vim-easymotion'                        " trigger with <leader><leader>+s/w/gE
Plug 'skywind3000/asyncrun.vim'                         " Compile
Plug 'godlygeek/tabular'                                " align text
Plug 'tpope/vim-surround'                               " change surroundings
                                                        " c[ange]s[old parttern] [new partten]
                                                        " ds[partten]
                                                        " ys(iww)[partten] / yss)
Plug 'tpope/vim-repeat'                                 " for use . to repeat for surround
Plug 'chxuan/tagbar'                                    " show params and functions


" Writing Blog
Plug 'hotoo/pangu.vim', {'for': ['markdown']}                                   "to make your document better
Plug 'godlygeek/tabular', {'for': ['markdown']}
Plug 'plasticboy/vim-markdown', {'for': ['markdown']}
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


" Apperance
Plug 'itchyny/lightline.vim'
Plug 'flazz/vim-colorschemes'
Plug 'Yggdroot/indentLine'                                                      " Show indent line
Plug 'bling/vim-bufferline'                                                     " 为打开的文件有一个快捷栏
Plug 'kshenoy/vim-signature'                                                    " Visible Mark
Plug 'junegunn/vim-slash'                                                       " clean hightline after search
Plug 'luochen1990/rainbow'                                                      " multi color for Parentheses
Plug 'therubymug/vim-pyte'                                                      " theme pyte
Plug 'vim-scripts/mayansmoke'
" https://github.com/vim-scripts/mayansmoke
Plug 'vim-scripts/peaksea'

" Github
Plug 'tpope/vim-fugitive'
Plug 'mattn/gist-vim'
Plug 'mattn/webapi-vim'
Plug 'junegunn/vim-github-dashboard', { 'on': ['GHDashboard', 'GHActivity'] }   " visit github in vim 
Plug 'junegunn/gv.vim'

" Search
Plug 'tpope/vim-abolish'                                                        "增强版的substitue
                                                                                ":%S/{man,dog}/{dog,man}/g 替换man和dog的位置
Plug 'Yggdroot/LeaderF'                                                         " Ultra search tools
Plug 'mileszs/ack.vim'                                                          " Use to search pattern in files
```

Old Plugin Configure Backup
---------------------------
### YouCompleteMe
1. *add `~/.vim.ycm_extra_conf.py` follow the instructions in [here](https://jonasdevlieghere.com/a-better-youcompleteme-config/)*
2. put config below to the vimrc
```bash

YouCompleteMe
let g:ycm_min_num_of_chars_for_completion = 2
"Preview windows settings
set splitbelow  "set preview window below
let g:ycm_add_preview_to_completeopt = 1
let g:ycm_autoclose_preview_window_after_completion = 0
let g:ycm_autoclose_preview_window_after_insertion = 0
let g:ycm_show_diagnostics_ui = 0
let g:ycm_server_log_level = 'info'
let g:ycm_cache_omnifunc=0
" 禁止缓存匹配项,每次都重新生成匹配项
"leave '<tab>', '<c-j>' for ultisnips
let g:ycm_key_list_select_completion = ['<c-n>', '<Down>']
"leave '<s-tab>', '<c-k>' for ultisnips
let g:ycm_key_list_previous_completion = ['<c-p>', '<Up>']
nnoremap <leader>lo :lopen<CR>
nnoremap <leader>lc :lclose<CR>

" 开启各种补全引擎
let g:ycm_auto_trigger = 1                  " 开启 YCM 基于标识符补全，默认为1
let g:ycm_seed_identifiers_with_syntax=1                " 开启 YCM 基于语法关键字补全
let g:ycm_complete_in_comments = 1              " 在注释输入中也能补全
let g:ycm_complete_in_strings = 1               " 在字符串输入中也能补全
let g:ycm_collect_identifiers_from_comments_and_strings = 1 " 注释和字符串中的文字也会被收入补全
let g:ycm_collect_identifiers_from_tags_files=1         " 开启 YCM 基于标签引擎
let g:ycm_python_binary_path='/usr/local/bin/python3'
let g:ycm_server_python_interpreter='/usr/local/bin/python3'

nnoremap <leader>jd :YcmCompleter GoToDefinitionElseDeclaration<CR>
nnoremap <leader>jd :YcmCompleter GoToDeclaration<CR>
"跳转到定义处
let g:ycm_confirm_extra_conf = 0
let g:ycm_global_ycm_extra_conf = '~/.vim/.ycm_extra_conf.py'
let g:ycm_key_list_select_completion=[]
let g:ycm_key_list_previous_completion=[]
let g:ycm_filetype_blacklist = {
            \ 'tagbar' : 1,
            \ 'qf' : 1,
            \ 'notes' : 1,
            \ 'markdown' : 1,
            \ 'unite' : 1,
            \ 'text' : 1,
            \ 'vimwiki' : 1,
            \ 'pandoc' : 1,
            \ 'infolog' : 1,
            \ 'mail' : 1
            \}

let g:ycm_semantic_triggers =  {
            \ 'c' : ['->', '.'],
            \ 'objc' : ['->', '.'],
            \ 'ocaml' : ['.', '#'],
            \ 'cpp,objcpp' : ['->', '.', '::'],
            \ 'perl' : ['->'],
            \ 'php' : ['->', '::'],
            \ 'cs,java,javascript,d,python,perl6,scala,vb,elixir,go' : ['.'],
            \ 'vim' : ['re![_a-zA-Z]+[_\w]*\.'],
            \ 'ruby' : ['.', '::'],
            \ 'lua' : ['.', ':'],
            \ 'erlang' : [':'],
            \ 'css': ['re!^\s{4}', 're!:\s+'],
            \ 'html': ['</'],
            \}

```
