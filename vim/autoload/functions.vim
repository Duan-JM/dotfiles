" ==========================================
" Autoload predefined Functions
"     ChangeLog:
"         2020-09-25: init functions
" ==========================================

" Set tabline
if exists("+showtabline")

  " Rename tabs to show tab number.
  " (Based on http://stackoverflow.com/questions/5927952/whats-implementation-of-vims-default-tabline-function)
  function! ShowTabNumbers()
      let s = ''
      let t = tabpagenr()
      let i = 1
      while i <= tabpagenr('$')
          let buflist = tabpagebuflist(i)
          let winnr = tabpagewinnr(i)
          let s .= '%' . i . 'T'
          let s .= (i == t ? '%1*' : '%2*')

          " let s .= (i == t ? '%#TabLineSel#' : '%#TabLine#')
          " let s .= ' '
          let s .= (i == t ? '%#TabNumSel#' : '%#TabNum#')
          let s .= ' ' . i . ' '
          let s .= (i == t ? '%#TabLineSel#' : '%#TabLine#')

          let bufnr = buflist[winnr - 1]
          let file = bufname(bufnr)
          let buftype = getbufvar(bufnr, '&buftype')

          if buftype == 'help'
              let file = 'help:' . fnamemodify(file, ':t:r')

          elseif buftype == 'quickfix'
              let file = 'quickfix'

          elseif buftype == 'nofile'
              if file =~ '\/.'
                  let file = substitute(file, '.*\/\ze.', '', '')
              endif

          else
              let file = pathshorten(fnamemodify(file, ':p:~:.'))
              if getbufvar(bufnr, '&modified')
                  let file = '+' . file
              endif

          endif

          if file == ''
              let file = '[No Name]'
          endif

          let s .= ' ' . file

          let nwins = tabpagewinnr(i, '$')
          if nwins > 1
              let modified = ''
              for b in buflist
                  if getbufvar(b, '&modified') && b != bufnr
                      let modified = '*'
                      break
                  endif
              endfor
              let hl = (i == t ? '%#WinNumSel#' : '%#WinNum#')
              let nohl = (i == t ? '%#TabLineSel#' : '%#TabLine#')
              let s .= ' ' . modified . '(' . hl . winnr . nohl . '/' . nwins . ')'
          endif

          if i < tabpagenr('$')
              let s .= ' %#TabLine#|'
          else
              let s .= ' '
          endif

          let i = i + 1

      endwhile

      let s .= '%T%#TabLineFill#%='
      let s .= (tabpagenr('$') > 1 ? '%999XX' : 'X')
      return s

  endfunction

  " set showtabline=1
  highlight! TabNum term=bold,underline cterm=bold,underline ctermfg=1 ctermbg=7 gui=bold,underline guibg=LightGrey
  highlight! TabNumSel term=bold,reverse cterm=bold,reverse ctermfg=1 ctermbg=7 gui=bold
  highlight! WinNum term=bold,underline cterm=bold,underline ctermfg=11 ctermbg=7 guifg=DarkBlue guibg=LightGrey
  highlight! WinNumSel term=bold cterm=bold ctermfg=7 ctermbg=14 guifg=DarkBlue guibg=LightGrey

  set tabline=%!ShowTabNumbers()
endif


"普通模式和可视模式下&都代表着重复上一次搜索操作，同时保持上一次的搜索域
nnoremap & :&&<CR>
xnoremap & :&&<CR>

" 可视模式下，用 * 和 # 搜索选中文本
xnoremap * :<C-u>call <SID>VSetSearch()<CR>/<C-r>=@/<CR><CR>
xnoremap # :<C-u>call <SID>VSetSearch()<CR>?<C-r>=@/<CR><CR>

function! s:VSetSearch()
    let temp = @s
    norm! gv"sy
    let @/ = '\V' . substitute(escape(@s, '/\'), '\n', '\\n', 'g')
    let @s = temp
endfunction

function! Stab()
    "设置缩进
    let l:tabstop = 1 * input('set tabstop = softtabstop = shiftwidth = ')
    if l:tabstop > 0
        let &l:sts = l:tabstop
        let &l:ts = l:tabstop
        let &l:sw = l:tabstop
    endif
    call SummarizeTabs()
endfunction

function! SummarizeTabs()
    "查看当前的缩进情况
    try
        echohl ModeMsg
        echon 'tabstop='.&l:ts
        echon ' shiftwidth='.&l:sw
        echon ' softtabstop='.&l:sts
        if &l:et
            echon ' expandtab'
        else
            echon ' noexpandtab'
        endif
    finally
        echohl None
    endtry
endfunction

" url:http://vimcasts.org/episodes/tidying-whitespace/
function! Preserve(command)
    " Preparation: save last search, and cursor position.
    let _s=@/
    let l = line('.')
    let c = col('.')
    " Do the business:
    execute a:command
    " Clean up: restore previous search history, and cursor position
    let @/=_s
    call cursor(l, c)
endfunction

"Allow to toggle background
function!  ToggleBG()
    let s:tbg = &background
    " Inversion
    if s:tbg == 'light'
        set background=dark
    else
        set background=light
    endif
endfunction

" set background transparable
func! s:transparent_background()
    highlight Normal guibg=NONE ctermbg=NONE
    highlight NonText guibg=NONE ctermbg=NONE
endf
autocmd ColorScheme * call s:transparent_background()

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                             Set Custom Commands                             "
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Set rename command
command! -nargs=1 Rename let tpname = expand('%:t') | saveas <args> | edit <args> | call delete(expand(tpname))
" Set Stab command: tabstop, softtabstop and shiftwidth to the same value
command! -nargs=* Stab call Stab()


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                            Set custom Shortcuts                             "
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" clean space in the end of line
nnoremap _$ :call Preserve("%s/\\s\\+$//e")<CR>
" clean extra whitespace in whole docs
nnoremap _= :call Preserve("normal gg=G")<CR>

" set background is dark at the startup
set background=dark
noremap <leader>bg :call ToggleBG()<CR>

function! functions#init_functions()
  echom "functions activated"
endfunction
