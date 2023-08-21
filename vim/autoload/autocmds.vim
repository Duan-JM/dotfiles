" ===================================
" Set Custom AUTOCMD for vim
" ===================================

" Check for vim-plug if not exist download it
if filereadable('~/.vim/autoload/plug.vim')
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
        \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  augroup vimplug
    au!
    autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
  augroup END
endif

" config for all file type =====>
" Return to last edit position when opening files (You want this!)
autocmd BufReadPost *
            \ if &filetype != "gitcommit" && line("'\"") > 0 && line("'\"") <= line("$") |
            \   exe "normal! g`\"" |
            \ endif

"https://superuser.com/questions/195022/vim-how-to-synchronize-nerdtree-with-current-opened-tab-file-path
if expand("%:p")
    autocmd BufEnter * lcd %:p:h
endif
"http://inlehmansterms.net/2014/09/04/sane-vim-working-directories/
"http://vim.wikia.com/wiki/Set_working_directory_to_the_current_file
autocmd BufEnter * silent! lcd %:p:h
autocmd BufEnter * if expand("%:p:h") !~ '^/tmp' | silent! lcd %:p:h | endif
let s:default_path = escape(&path, '\ ') " store default value of 'path'


autocmd CursorMovedI,InsertLeave * if pumvisible() == 0|silent! pclose|endif    " Automatically open and close the popup menu / preview window

autocmd FocusGained, BufEnter * :silent! !

autocmd! FileType gitcommit autocmd! BufEnter COMMIT_EDITMSG
            \ call setpos('.', [0, 1, 1, 0])                                    " set it to the first line when editing a git commit message

" config for tex
autocmd! FileType tex set spell |
            \ set spelllang=en_us |
            \ set wrap |
            \ set whichwrap=b,s,h,l,<,>,>h,[,]                                  " Do not wrap long lines


autocmd vimenter * hi Normal guibg=NONE ctermbg=NONE " transparent bg

" config for python
autocmd! FileType python set tabstop=4  softtabstop=4 shiftwidth=4 expandtab textwidth=79

" config for yaml
autocmd! FileType yaml set tabstop=2  softtabstop=2 shiftwidth=2 expandtab textwidth=79

func! autocmds#init_autocmds()
  echom "custom autocmds activated"
endfunc
