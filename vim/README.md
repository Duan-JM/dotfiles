Welcome to MyVimrc
==================
TODO LIST
--------
- [ ] Rewrite using and install manual

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
Plug 'voldikss/vim-translate-me'

" System
Plug 'vim-scripts/LargeFile'                            " Fast Load for Large files
Plug 'michaeljsmith/vim-indent-object'                  " used for align
Plug 'terryma/vim-smooth-scroll'                        " smooth scroll
Plug 'wellle/targets.vim'                               " text objects
Plug 'ryanoasis/vim-devicons'                           " extensions for icons
Plug 'brglng/vim-im-select'                             " auto change input methods, needs `imselect` cmd

" Coding
Plug 'Shougo/deoplete.nvim', {'do': ':UpdateRemotePlugins'}
Plug 'davidhalter/jedi-vim'
Plug 'deoplete-plugins/deoplete-jedi'
Plug 'w0rp/ale'                                         " Syntax Check
Plug 'SirVer/ultisnips'                                 " snippets
Plug 'Duan-JM/vdeamov-snippets'
Plug 'tpope/vim-commentary'
Plug 'Raimondi/delimitMate'                             " Brackets Jump 智能补全括号和跳转
                                                        " 补全括号 shift+tab出来
Plug 'vim-scripts/matchit.zip'                          " %  g% [% ]% a%
Plug 'andymass/vim-matchup'                             " extence
Plug 'octol/vim-cpp-enhanced-highlight', {'for':['c', 'cpp']}
Plug 'easymotion/vim-easymotion'                        " trigger with <leader><leader>+s/w/gE
Plug 'godlygeek/tabular'                                " align text
Plug 'tpope/vim-surround'                               " change surroundings
                                                        " c[ange]s[old parttern] [new partten]
                                                        " ds[partten]
                                                        " ys(iww)[partten] / yss)
Plug 'tpope/vim-repeat'                                 " for use . to repeat for surround
Plug 'liuchengxu/vista.vim', {'for':['c', 'cpp', 'python']}                     " show params and functions

" Writing Blog
Plug 'rhysd/vim-grammarous', {'for': ['markdown', 'tex']}                       " grammarly checks
Plug 'hotoo/pangu.vim', {'for': ['markdown']}                                   "to make your document better
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
Plug 'deoplete-plugins/deoplete-dictionary'


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
Plug 'kshenoy/vim-signature'                                                    " Visible Mark
Plug 'luochen1990/rainbow'                                                      " multi color for Parentheses
Plug 'vim-scripts/peaksea'
Plug 'haishanh/night-owl.vim'
Plug 'nightsense/stellarized'
Plug 'nightsense/cosmic_latte'

" Github
Plug 'mattn/gist-vim'
Plug 'mattn/webapi-vim'
Plug 'tpope/vim-fugitive'
Plug 'junegunn/gv.vim'                                                          " Rely on fugitive
Plug 'airblade/vim-gitgutter'                                                   " [c ]c jump to prev/next change [C ]C

" Search
Plug 'tpope/vim-abolish'                                                        "增强版的substitue
Plug 'Yggdroot/LeaderF'                                                         " Ultra search tools
                                                                                " <c-]> open in vertical 
Plug 'junegunn/vim-slash'                                                       " clean hightline after search
Plug 'brooth/far.vim'                                                           " search and replace
```

TIPS Usage
----------
### Searching & Navigating
1. Search files names

We use `Leaderf` to search files, use `<c-p>` to trigger the plugin, use `<c-]>` to open the file vertially.

2. Search content of lots of files

We use `far` plugin to search the content in a bunch of files. 
Using `<space>s/` to triger the command line, using `:F foo file_mask` to
search. eg, `:F test **/*.py` search test in all `py` file in the folder.

3. Navigate between buffers and functions

we also use `LeaderF` or `Vista` to navigate between buffers and functions. We
use `<A-b>` to trigger the list of buffers, use `<A-m>` to trigger the
functions list (also work in markdown files).


4. Tabs Controls
We use `<leader>t` to create a new tab, `<leader>v` to create a new tab
vertically and `<leader>tq` to close tabs and `<leader>tn` to switch tabs.
