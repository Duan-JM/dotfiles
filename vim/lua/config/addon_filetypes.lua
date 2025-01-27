-- =================
-- Config Filetypes
-- =================

-- Reset any existing autocmds for filetypes
vim.cmd("autocmd! BufNewFile,BufRead *.markdown,*.md set filetype=markdown")
vim.cmd("autocmd! BufNewFile,BufRead *.ts set filetype=typescript")
vim.cmd("autocmd! BufNewFile,BufRead *.json set filetype=json")
vim.cmd("autocmd! BufNewFile,BufRead,BufReadPost *.snippets set filetype=snippets")
vim.cmd("autocmd! BufNewFile,BufRead *.vs,*.fs set filetype=glsl")
vim.cmd("autocmd! BufNewFile,BufRead *.swift set filetype=swift")
vim.cmd("autocmd! BufNewFile,BufRead *.vm,*.xtpl,*.ejs set filetype=html")
vim.cmd("autocmd! BufNewFile,BufRead *.html.twig set filetype=html.twig")
vim.cmd("autocmd! BufNewFile,BufRead *.conf set filetype=config")
vim.cmd("autocmd! BufRead,BufNewFile *.scss set filetype=scss.css")
vim.cmd("autocmd! BufNewFile,BufRead *.coffee set filetype=coffee")
vim.cmd("autocmd! BufNewFile,BufRead *.rss,*.atom set filetype=xml")
vim.cmd("autocmd! BufNewFile,BufRead *.vm set ft=velocity")
vim.cmd("autocmd! BufNewFile,BufRead *.mako set ft=mako")
vim.cmd("autocmd! BufNewFile,BufRead *.tex set filetype=tex")
vim.cmd("autocmd! BufNewFile,BufRead *.bat if getline(1) =~ '--\\*-Perl-\\*--' | setf perl | endif")
