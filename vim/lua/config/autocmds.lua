-- ===========================================================================
-- Autocommands
-- ===========================================================================
local autocmd = vim.api.nvim_create_autocmd
local function augroup(name)
	return vim.api.nvim_create_augroup("user_" .. name, { clear = true })
end

-- Restore last cursor position when reopening files (skip gitcommit).
autocmd("BufReadPost", {
	group = augroup("last_pos"),
	callback = function()
		if vim.bo.filetype == "gitcommit" then return end
		local mark = vim.api.nvim_buf_get_mark(0, '"')
		local lcount = vim.api.nvim_buf_line_count(0)
		if mark[1] > 0 and mark[1] <= lcount then
			pcall(vim.api.nvim_win_set_cursor, 0, mark)
		end
	end,
})

-- Change local working dir to the current file's directory (skip /tmp and
-- special buffers like terminal, quickfix, neo-tree).
autocmd("BufEnter", {
	group = augroup("auto_lcd"),
	callback = function()
		if vim.bo.buftype ~= "" then return end
		local dir = vim.fn.expand("%:p:h")
		if dir == "" or dir:match("^/tmp") then return end
		pcall(vim.cmd, "silent! lcd " .. vim.fn.fnameescape(dir))
	end,
})

-- Close preview window when the popup menu is gone.
autocmd({ "CursorMovedI", "InsertLeave" }, {
	group = augroup("close_pum"),
	callback = function()
		if vim.fn.pumvisible() == 0 then
			pcall(vim.cmd, "silent! pclose")
		end
	end,
})

-- Detect external file changes (the original `silent! !` was a no-op shell
-- call; `checktime` is what was intended).
autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
	group = augroup("checktime"),
	callback = function()
		if vim.fn.mode() ~= "c" then
			pcall(vim.cmd, "checktime")
		end
	end,
})

-- For git commit / merge / rebase: jump to the first line so the user starts
-- typing immediately.
autocmd("BufReadPost", {
	group = augroup("gitcommit_first_line"),
	pattern = { "COMMIT_EDITMSG", "MERGE_MSG" },
	callback = function() vim.fn.setpos(".", { 0, 1, 1, 0 }) end,
})

-- Transparent background on entry and after every colorscheme change.
autocmd({ "VimEnter", "ColorScheme" }, {
	group = augroup("transparent"),
	callback = function()
		vim.cmd("highlight Normal      guibg=NONE ctermbg=NONE")
		vim.cmd("highlight NormalNC    guibg=NONE ctermbg=NONE")
		vim.cmd("highlight EndOfBuffer guibg=NONE ctermbg=NONE")
		vim.cmd("highlight SignColumn  guibg=NONE ctermbg=NONE")
	end,
})

-- Filetype-specific options ----------------------------------------------------
local ft = augroup("ft_opts")

autocmd("FileType", {
	group = ft,
	pattern = "tex",
	callback = function()
		vim.opt_local.spell = true
		vim.opt_local.spelllang = "en_us"
		vim.opt_local.wrap = true
	end,
})

autocmd("FileType", {
	group = ft,
	pattern = "python",
	callback = function()
		vim.opt_local.tabstop = 4
		vim.opt_local.softtabstop = 4
		vim.opt_local.shiftwidth = 4
		vim.opt_local.expandtab = true
		vim.opt_local.textwidth = 79
	end,
})

autocmd("FileType", {
	group = ft,
	pattern = { "yaml", "yml" },
	callback = function()
		vim.opt_local.tabstop = 2
		vim.opt_local.softtabstop = 2
		vim.opt_local.shiftwidth = 2
		vim.opt_local.expandtab = true
	end,
})

-- Highlight on yank (nice quality-of-life feedback).
autocmd("TextYankPost", {
	group = augroup("highlight_yank"),
	callback = function()
		(vim.hl or vim.highlight).on_yank({ timeout = 200 })
	end,
})
