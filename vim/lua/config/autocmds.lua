-- ===================================
-- Set Custom AUTOCMD for vim
-- ===================================
-- config for all file type =====>
-- Return to last edit position when opening files (You want this!)
vim.api.nvim_create_autocmd("BufReadPost", {
    callback = function()
        local ft = vim.bo.filetype
        local last_pos = vim.fn.line("'\"")
        local last_line = vim.fn.line("$")
        
        -- 如果文件类型不是 gitcommit 且上次位置有效，则跳转到上次位置
        if ft ~= "gitcommit" and last_pos > 0 and last_pos <= last_line then
            vim.cmd("normal! g`\"")
        end
    end,
})

-- https://superuser.com/questions/195022/vim-how-to-synchronize-nerdtree-with-current-opened-tab-file-path
if vim.fn.expand("%:p") ~= "" then
    vim.api.nvim_create_autocmd("BufEnter", {
        pattern = "*",
        callback = function()
            -- 设置当前工作目录为当前文件的所在目录
            vim.cmd("lcd " .. vim.fn.expand("%:p:h"))
        end,
    })
end
-- http://inlehmansterms.net/2014/09/04/sane-vim-working-directories/
-- http://vim.wikia.com/wiki/Set_working_directory_to_the_current_file
vim.api.nvim_create_autocmd("BufEnter", {
    pattern = "*",
    callback = function()
        local dir = vim.fn.expand("%:p:h")
        if dir ~= "" then
            vim.cmd("silent! lcd " .. dir)
        end
    end,
})
vim.api.nvim_create_autocmd("BufEnter", {
    pattern = "*",
    callback = function()
        local dir = vim.fn.expand("%:p:h")
        if dir ~= "" and not dir:match("^/tmp") then
            vim.cmd("silent! lcd " .. dir)
        end
    end,
})
local default_path = vim.o.path:gsub(" ", "\\ ")


local autocmd = vim.api.nvim_create_autocmd

-- 自动关闭预览窗口
autocmd({"CursorMovedI", "InsertLeave"}, {
    callback = function()
        if vim.fn.pumvisible() == 0 then
            vim.cmd("silent! pclose")
        end
    end,
})

-- 恢复焦点时刷新缓冲区
autocmd({"FocusGained", "BufEnter"}, {
    callback = function()
        vim.cmd("silent! !")
    end,
})

-- Git 提交消息相关设置
autocmd("FileType", {
    pattern = "gitcommit",
    callback = function()
        autocmd("BufEnter", {
            pattern = "COMMIT_EDITMSG",
            callback = function()
                vim.fn.setpos(".", {0, 1, 1, 0})
            end,
        })
    end,
})

-- TeX 文件的配置
autocmd("FileType", {
    pattern = "tex",
    callback = function()
        vim.opt_local.spell = true
        vim.opt_local.spelllang = "en_us"
        vim.opt_local.wrap = true
        vim.opt_local.whichwrap = "b,s,h,l,<,>,>h,[,]"
    end,
})

-- 启动时设置透明背景
autocmd("VimEnter", {
    callback = function()
        vim.cmd("hi Normal guibg=NONE ctermbg=NONE")
    end,
})

-- Python 文件的配置
autocmd("FileType", {
    pattern = "python",
    callback = function()
        vim.opt_local.tabstop = 4
        vim.opt_local.softtabstop = 4
        vim.opt_local.shiftwidth = 4
        vim.opt_local.expandtab = true
        vim.opt_local.textwidth = 79
    end,
})

-- YAML 文件的配置
autocmd("FileType", {
    pattern = "yaml",
    callback = function()
        vim.opt_local.tabstop = 2
        vim.opt_local.softtabstop = 2
        vim.opt_local.shiftwidth = 2
        vim.opt_local.expandtab = true
        vim.opt_local.textwidth = 79
    end,
})
