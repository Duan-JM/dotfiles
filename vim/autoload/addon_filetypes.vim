" =================
" Config Filetypes
" =================
autocmd! BufNewFile,BufRead *.markdown *.md set filetype=markdown
autocmd! BufNewFile,BufRead *.ts set filetype=typescript
autocmd! BufNewFile,BufRead *.json set filetype=json
autocmd! BufNewFile,BufRead,BufReadPost *.snippets set filetype=snippets
autocmd! BufNewFile,BufRead *.vs,*.fs set filetype=glsl
autocmd! BufNewFile,BufRead *.swift set filetype=swift
autocmd! BufNewFile,BufRead *.vm *.xtpl *.ejs set filetype=html
autocmd! BufNewFile,BufRead *.html.twig set filetype=html.twig
autocmd! BufNewFile,BufRead *.conf set filetype=config
autocmd! BufRead,BufNewFile *.scss set filetype=scss.css
autocmd! BufNewFile,BufRead *.coffee set filetype=coffee
autocmd! BufNewFile,BufRead *.rss *.atom setfiletype xml
autocmd! BufNewFile,BufRead *.vm set ft=velocity
autocmd! BufNewFile,BufRead *.mako set ft=mako
autocmd! BufNewFile,BufRead *.tex set filetype=tex
autocmd! BufNewFile,BufRead *.bat
            \ if getline(1) =~ '--\*-Perl-\*--' | setf perl | endif

func! addon_filetypes#init_filetypes()
  echom "custom filetypes activated"
endfunc
