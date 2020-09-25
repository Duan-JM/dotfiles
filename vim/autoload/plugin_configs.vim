" ==================
" Plugin Configures
" ==================

" APZelos/blamer.nvim
let g:blamer_enabled = 1           " auto enable
let g:blamer_show_in_visual_modes = 0

" skywind3000/asynctasks.vim
let g:asyncrun_open=6
let g:asyncrun_rootmarks = ['.git', '.svn', '.root', '.project', '.hg']
let g:asynctasks_term_pos = 'bottom'
let g:asynctasks_term_rows = 10    " 设置纵向切割时，高度为 10
let g:asynctasks_term_cols = 80    " 设置横向切割时，宽度为 80
nnoremap <leader>r :AsyncTask file-run<cr>
nnoremap <leader>b :AsyncTask file-build<cr>

" vim-floaterm
tnoremap <c-[> <c-\><c-n>
nnoremap <leader>` :FloatermToggle<cr>

" quick-scope
let g:qs_highlight_on_keys = ['f', 'F', 't', 'T']
" Trigger a highlight in the appropriate direction when pressing these keys:
augroup qs_colors
  autocmd!
  autocmd ColorScheme * highlight QuickScopePrimary guifg='#afff5f' gui=underline ctermfg=155 cterm=underline
  autocmd ColorScheme * highlight QuickScopeSecondary guifg='#5fffff' gui=underline ctermfg=81 cterm=underline
augroup END

" ncm2/float-preview.nvim
let g:float_preview#docked = 0

" translate-me
let g:vtm_default_mapping = 0
let g:vtm_target_lang = 'en' " default translate to english
let g:vtm_default_engines = ['ciba', 'youdao']
" let g:vtm_proxy_url = 'socks5://127.0.0.1:1080'

" <Leader>zt 翻译光标下的文本，在命令行回显
nmap <silent> <Leader>zt <Plug>Translate
vmap <silent> <Leader>zt <Plug>TranslateV
" Leader>zw 翻译光标下的文本，在窗口中显示
nmap <silent> <Leader>zw <Plug>TranslateW
vmap <silent> <Leader>zw <Plug>TranslateWV
" Leader>zr 替换光标下的文本为翻译内容
nmap <silent> <Leader>zr <Plug>TranslateR
vmap <silent> <Leader>zr <Plug>TranslateRV

"pathogen
execute pathogen#infect()

" rainbow
let g:rainbow_active = 1

"markdown-preview
let g:mkdp_browser = 'Safari'

" vim-smooth-scroll
" Distance Duration Speed
noremap <silent> <c-u> :call smooth_scroll#up(&scroll, 8, 2)<CR>
noremap <silent> <c-d> :call smooth_scroll#down(&scroll, 8, 2)<CR>
noremap <silent> <c-b> :call smooth_scroll#up(&scroll*2, 8, 4)<CR>
noremap <silent> <c-f> :call smooth_scroll#down(&scroll*2, 8, 4)<CR>


" junegunn/vim-slash
noremap <plug>(slash-after) zz
if has('timers')
  " Blink 2 times with 50ms interval
  noremap <expr> <plug>(slash-after) slash#blink(2, 50)
endif

"vim-latex-live-preview
autocmd Filetype tex setl updatetime=1
let g:livepreview_previewer = 'open -a Preview'

"vimtex
let g:tex_flavor='latex'
let g:vimtex_view_method='skim'
let g:vimtex_quickfix_mode=0
set conceallevel=1
let g:tex_conceal='abdmg'

"mhinz/vim-startify
let g:startify_list_order = [
            \ ['   Bookmarks'],     'bookmarks',
            \ ['   MRU'],           'files' ,
            \ ['   MRU '.getcwd()], 'dir',
            \ ]
let g:startify_bookmarks = [
            \ '~/Desktop/Github',
            \ '~/Documents/Coding/Test']
let g:startify_change_to_dir          = 0
let g:startify_enable_special         = 0
let g:startify_files_number           = 8
let g:startify_session_autoload       = 1
let g:startify_session_delete_buffers = 1
let g:startify_session_persistence    = 1
let g:startify_use_env                = 1

"scrooloose/nerdtree
nnoremap <leader>nt :NERDTreeToggle<CR>
let g:NERDTreeShowLineNumbers=1
let NERDTreeAutoCenter=1
let g:NERDTreeChDirMode=2
let NERDTreeWinPos="left"
let g:nerdtree_tabs_open_on_console_startup=1
let g:NERDTreeShowBookmarks=1
let g:NERDTreeIgnore=['\.pyc','\~$','\.swp','\.DS_Store']

"vim-table-mode
let g:table_mode_corner = '|'
let g:table_mode_delimiter = ' '
let g:table_mdoe_verbose = 0
let g:table_mode_auto_align = 0
"autocmd FileType markdown TableModeEnable

"vim-markdown
let g:vim_markdown_math=1

"vim-markdown-toc
let g:vmt_auto_update_on_save=1 "update toc when save
let g:vmt_dont_insert_fence=0 "if equals to 1, can't update toc when save

"gist-vim
let github_user='Duan-JM'


"Yggdroot/indentLine
let g:indentLine_enabled=0
let g:indentLine_char_list = ['|', '¦', '┆', '┊']

"LeaderF
let g:Lf_HideHelp = 1
let g:Lf_UseCache = 0
let g:Lf_UseVersionControlTool = 0
let g:Lf_IgnoreCurrentBufferName = 1 " auto refresh index [issue](https://github.com/Yggdroot/LeaderF/issues/161)
let g:Lf_ShortcutF = '<c-p>'

let g:Lf_StlColorscheme = 'gruvbox_material'
let g:Lf_StlSeparator = { 'left': "\ue0b0", 'right': "\ue0b2", 'font': "DejaVu Sans Mono for Powerline" }
let g:Lf_PreviewResult = {'Function': 0, 'BufTag': 0 }
let g:Lf_SpinSymbols = ['△', '▲', '▷', '▶', '▽', '▼', '◁', '◀']
let g:Lf_CacheDirectory = expand('~/.vim/cache')
let g:Lf_RootMarkers = ['.project', '.root', '.svn', '.git']
let g:Lf_WorkingDirectoryMode = 'Ac'
let g:Lf_WindowHeight = 0.30
let g:Lf_ShowRelativePath = 0

noremap <leader>fb :Leaderf buffer<CR>
noremap <leader>ft :Leaderf function<CR>
noremap <leader>fl :<c-r>=printf("Leaderf line %s", "")<CR>

" need install rg
noremap <leader><c-b> :<c-r>=printf("Leaderf! rg --current-buffer -e %s ", expand("<cword>"))
noremap <leader><c-f> :<c-r>=printf("Leaderf! rg -e %s ", expand("<cword>"))<cr>
" search visually selected text literally
xnoremap gf :<c-r>=printf("Leaderf! rg -F -e %s ", leaderf#Rg#visual())<cr>
noremap go :Leaderf! rg --recall<cr>


" vista.vim
let g:vista_icon_indent = ["╰─▸ ", "├─▸ "]
left g:vista_default_executive = 'ctags'
let g:vista#renderer#enable_icon = 1

" The default icons can't be suitable for all the filetypes, you can extend it as you wish.
let g:vista#renderer#icons = {
\   "function": "\uf794",
\   "variable": "\uf71b",
\  }

"LightLine
"ayu_dark / simple black
let g:lightline = {
     \ 'colorscheme': 'edge',
     \ 'active': {
     \   'left': [ 
     \     [ 'mode', 'paste' ],
     \     [ 'filename', 'modified' ],
     \     [ 'gitbranch' ],
     \     [ 'cocstatus' ],
     \   ],
     \ 'right': [
     \     ['lineinfo'],
     \     ['percent'],
     \     ['linter_checking', 'linter_errors', 'linter_warnings', 'linter_infos', 'linter_ok' ]
     \   ],
     \ },
     \ 'separator': {
     \   'left': '',
     \   'right': ''
     \ },
     \ 'component_function': {
     \   'gitbranch': 'fugitive#head',
     \   'cocstatus': 'coc#status',
     \ },
     \ 'component_type': {
     \   'readonly':        'error',
     \   'linter_infos': 'right',
     \   'linter_warnings': 'warning',
     \   'linter_errors': 'error',
     \   'linter_ok': 'right',
     \ },
     \ 'component_expand': {
     \     'linter_checking': 'lightline#ale#checking',
     \     'linter_infos': 'lightline#ale#infos',
     \     'linter_warnings': 'lightline#ale#warnings',
     \     'linter_errors': 'lightline#ale#errors',
     \     'linter_ok': 'lightline#ale#ok',
     \   },
     \ 'enable': {
     \   'statusline': 1,
     \   'tabline': 0
     \ }
     \}

"SirVer/ultisnips
"customize python and keymapping
"ref:https://gist.github.com/lencioni/dff45cd3d1f0e5e23fe6
"ref:https://stackoverflow.com/questions/14896327/ultisnips-and-youcompleteme
let g:snips_author = 'Duan-JM'
let g:snips_email = 'vincent.duan95@outlook.com'
let g:snips_github = 'https://github.com/Duan-JM'
let g:ultisnips_python_style = 'google'

"dense-analysis/ale
let g:ale_linters_explicit = 1
let g:ale_completion_delay = 500
let g:ale_echo_delay = 20
let g:ale_lint_delay = 500
let g:ale_echo_msg_format = '[%linter%] %code: %%s'
let g:ale_lint_on_text_changed = 'normal'
let g:ale_lint_on_insert_leave = 1
let g:ale_c_gcc_options = '-Wall -O2 -std=c99'
let g:ale_cpp_gcc_options = '-Wall -O2 -std=c++14'
let g:ale_c_cppcheck_options = ''
let g:ale_cpp_cppcheck_options = ''
let g:ale_sign_eror = 'E'
let g:ale_sign_warning = 'W'
let g:ale_linters = {
\   'python': ['pylint'],
\   'tex': ['lacheck'],
\   'swift': ['swiftlint'],
\   'markdown': ['markdownlint'],
\   'cpp': ['gcc', 'cpplint'],
\   'c': ['gcc', 'cpplint'],
\   'java': ['javac','google-java-format'],
\}
let g:ale_fixers = {
\   '*': ['remove_trailing_lines','trim_whitespace' ],
\   'python': ['autopep8', 'yapf']
\}
"Use :ALEFix to fix
"let g:ale_fix_on_save = 1 "auto Sava
let g:ale_list_window_size = 5

func plugin_configs#init_plugin_configs()
  echom "plugin configs activated"
endfunc
