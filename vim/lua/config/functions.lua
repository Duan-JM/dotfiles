-- ==========================================
-- Autoload predefined Functions
-- ==========================================

-- ShowTabNumbers function
function show_tab_numbers()
    local s = ''
    local t = vim.fn.tabpagenr()
    for i = 1, vim.fn.tabpagenr('$') do
        local buflist = vim.fn.tabpagebuflist(i)
        local winnr = vim.fn.tabpagewinnr(i)
        s = s .. '%' .. i .. 'T'
        s = s .. (i == t and '%1*' or '%2*')

        -- local bufnr = buflist[winnr - 1]
        -- TODO: maybe bug here when trans to lua
        local bufnr = buflist[winnr]
        local file = vim.fn.bufname(bufnr)
        local buftype = vim.fn.getbufvar(bufnr, '&buftype')

        if buftype == 'help' then
            file = 'help:' .. vim.fn.fnamemodify(file, ':t:r')
        elseif buftype == 'quickfix' then
            file = 'quickfix'
        elseif buftype == 'nofile' then
            if string.match(file, '\\.') then
                file = string.gsub(file, '.*\\/\\ze.', '')
            end
        else
            file = vim.fn.pathshorten(vim.fn.fnamemodify(file, ':p:~:.'))
            if vim.fn.getbufvar(bufnr, '&modified') == 1 then
                file = '+' .. file
            end
        end

        if file == '' then
            file = '[No Name]'
        end

        s = s .. ' ' .. file

        local nwins = vim.fn.tabpagewinnr(i, '$')
        if nwins > 1 then
            local modified = ''
            for _, b in ipairs(buflist) do
                if vim.fn.getbufvar(b, '&modified') == 1 and b ~= bufnr then
                    modified = '*'
                    break
                end
            end
            local hl = (i == t and '%#WinNumSel#' or '%#WinNum#')
            local nohl = (i == t and '%#TabLineSel#' or '%#TabLine#')
            s = s .. ' ' .. modified .. '(' .. hl .. winnr .. nohl .. '/' .. nwins .. ')'
        end

        if i < vim.fn.tabpagenr('$') then
            s = s .. ' %#TabLine#|'
        else
            s = s .. ' '
        end
    end
    s = s .. '%T%#TabLineFill#%='
    s = s .. (vim.fn.tabpagenr('$') > 1 and '%999XX' or 'X')
    return s
end

if vim.fn.exists('+showtabline') then
    vim.cmd('highlight! TabNum term=bold,underline cterm=bold,underline ctermfg=1 ctermbg=7 gui=bold,underline guibg=LightGrey')
    vim.cmd('highlight! TabNumSel term=bold,reverse cterm=bold,reverse ctermfg=1 ctermbg=7 gui=bold')
    vim.cmd('highlight! WinNum term=bold,underline cterm=bold,underline ctermfg=11 ctermbg=7 guifg=DarkBlue guibg=LightGrey')
    vim.cmd('highlight! WinNumSel term=bold cterm=bold ctermfg=7 ctermbg=14 guifg=DarkBlue guibg=LightGrey')

    vim.opt.tabline = '%!v:lua.show_tab_numbers()'
end

-- ==========================================
-- Custom Mappings
-- ==========================================

-- Normal and Visual Mode `&` for repeating the last search
vim.api.nvim_set_keymap('n', '&', ':&&<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('x', '&', ':&&<CR>', { noremap = true, silent = true })

-- Search for selected text in Visual mode using * and #
vim.api.nvim_set_keymap('x', '*', ':<C-u>call VSetSearch()<CR>/<C-r>=@/<CR><CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('x', '#', ':<C-u>call VSetSearch()<CR>?<C-r>=@/<CR><CR>', { noremap = true, silent = true })

-- Function to handle search in visual mode
function _G.VSetSearch()
    local temp = vim.fn.getreg('s')
    vim.cmd('normal! gv"sy')
    vim.fn.setreg('/', '\\V' .. string.gsub(vim.fn.escape(vim.fn.getreg('s'), '/\\'), '\n', '\\n'))
    vim.fn.setreg('s', temp)
end

-- ==========================================
-- Custom Commands
-- ==========================================

-- Rename command
vim.api.nvim_create_user_command('Rename', function(opts)
    local tpname = vim.fn.expand('%:t')
    vim.cmd('saveas ' .. opts.args)
    vim.cmd('edit ' .. opts.args)
    vim.fn.delete(tpname)
end, { nargs = 1 })

-- Stab command: Set tabstop, softtabstop, and shiftwidth to the same value
vim.api.nvim_create_user_command('Stab', function()
    local tabstop = tonumber(vim.fn.input('set tabstop = softtabstop = shiftwidth = '))
    if tabstop > 0 then
        vim.opt.sts = tabstop
        vim.opt.ts = tabstop
        vim.opt.sw = tabstop
    end
    SummarizeTabs()
end, { nargs = 0 })

-- SummarizeTabs function
function SummarizeTabs()
    pcall(function()
        vim.cmd('echohl ModeMsg')
        vim.cmd('echon "tabstop=" .. &ts')
        vim.cmd('echon " shiftwidth=" .. &sw')
        vim.cmd('echon " softtabstop=" .. &sts')
        if vim.opt.et:get() then
            vim.cmd('echon " expandtab"')
        else
            vim.cmd('echon " noexpandtab"')
        end
    end)
    vim.cmd('echohl None')
end
