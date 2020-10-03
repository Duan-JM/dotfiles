" ===================
" Coc Configurations
" ===================
" Need Manually Config
" :CocInstall coc-clangd coc-python coc-json coc-snippets coc-tabnine

" If not found clangd try manual link clangd to path
" ln -s /usr/local/Cellar/llvm/10.0.1/bin/clangd /usr/local/bin/clangd


" ====> Global Config
let g:coc_snippet_next = '<tab>'

" ====> Keymapping
" CocDiagnostics
" Use `[g` and `]g` to navigate diagnostics
" Use `:CocDiagnostics` to get all diagnostics of current buffer in location list.
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)

" Coding
" GoTo code navigation.
nmap <silent> <leader>jd <Plug>(coc-definition)
nmap <silent> <leader>jy <Plug>(coc-type-definition)
nmap <silent> <leader>ji <Plug>(coc-implementation)
nmap <silent> <leader>jr <Plug>(coc-references)

" Use K to show documentation in preview window.
nnoremap <silent> K :call <SID>show_documentation()<CR>

" Formatting selected code.
" DONOT change to xnoremap or nnoremap
xmap <leader>f  <Plug>(coc-format-selected)
nmap <leader>f  <Plug>(coc-format-selected)

" Remap keys for applying codeAction to the current buffer.
" Apply AutoFix to problem on the current line. DONOT change to nnoremap
nmap <leader>ac  <Plug>(coc-codeaction)
nmap <leader>qf  <Plug>(coc-fix-current)

" ====> Custom Commands
command! -nargs=0 Format :call CocAction('format')
command! -nargs=? Fold :call CocAction('fold', <f-args>)
command! -nargs=0 OR   :call CocAction('runCommand', 'editor.action.organizeImport')

" =====> Others
function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction

" Highlight the symbol and its references when holding the cursor.
" autocmd CursorHold * silent call CocActionAsync('highlight')



func! coc_configuration#init_coc_config()
  echom "coc config actiaved"
endfunc
