-- ===========================================================================
-- Custom functions, commands, and tabline
-- ===========================================================================

-- Custom tabline showing tab numbers and abbreviated paths.
function _G.show_tab_numbers()
	local s = ""
	local t = vim.fn.tabpagenr()
	for i = 1, vim.fn.tabpagenr("$") do
		local buflist = vim.fn.tabpagebuflist(i)
		local winnr = vim.fn.tabpagewinnr(i)
		s = s .. "%" .. i .. "T"
		s = s .. (i == t and "%1*" or "%2*")

		local bufnr = buflist[winnr]
		local file = vim.fn.bufname(bufnr)
		local buftype = vim.fn.getbufvar(bufnr, "&buftype")

		if buftype == "help" then
			file = "help:" .. vim.fn.fnamemodify(file, ":t:r")
		elseif buftype == "quickfix" then
			file = "quickfix"
		elseif buftype ~= "nofile" then
			file = vim.fn.pathshorten(vim.fn.fnamemodify(file, ":p:~:."))
			if vim.fn.getbufvar(bufnr, "&modified") == 1 then
				file = "+" .. file
			end
		end
		if file == "" then file = "[No Name]" end
		s = s .. " " .. file

		local nwins = vim.fn.tabpagewinnr(i, "$")
		if nwins > 1 then
			local modified = ""
			for _, b in ipairs(buflist) do
				if vim.fn.getbufvar(b, "&modified") == 1 and b ~= bufnr then
					modified = "*"
					break
				end
			end
			local hl   = (i == t and "%#WinNumSel#" or "%#WinNum#")
			local nohl = (i == t and "%#TabLineSel#" or "%#TabLine#")
			s = s .. " " .. modified .. "(" .. hl .. winnr .. nohl .. "/" .. nwins .. ")"
		end

		s = s .. (i < vim.fn.tabpagenr("$") and " %#TabLine#|" or " ")
	end
	s = s .. "%T%#TabLineFill#%="
	s = s .. (vim.fn.tabpagenr("$") > 1 and "%999XX" or "X")
	return s
end

if vim.fn.exists("+showtabline") == 1 then
	vim.cmd([[
		highlight! TabNum    term=bold,underline cterm=bold,underline ctermfg=1  ctermbg=7  gui=bold,underline guibg=LightGrey
		highlight! TabNumSel term=bold,reverse   cterm=bold,reverse   ctermfg=1  ctermbg=7  gui=bold
		highlight! WinNum    term=bold,underline cterm=bold,underline ctermfg=11 ctermbg=7  guifg=DarkBlue guibg=LightGrey
		highlight! WinNumSel term=bold           cterm=bold           ctermfg=7  ctermbg=14 guifg=DarkBlue guibg=LightGrey
	]])
	vim.opt.tabline = "%!v:lua.show_tab_numbers()"
end

-- Repeat last :substitute with its flags.
vim.keymap.set({ "n", "x" }, "&", "<cmd>&&<cr>", { desc = "Repeat last :s with flags" })

-- Visual-mode * / # to search for the selected text.
function _G.VSetSearch()
	local temp = vim.fn.getreg("s")
	vim.cmd('normal! gv"sy')
	local pat = vim.fn.escape(vim.fn.getreg("s"), [[/\]])
	pat = pat:gsub("\n", "\\n")
	vim.fn.setreg("/", "\\V" .. pat)
	vim.fn.setreg("s", temp)
end

vim.keymap.set("x", "*", [[:<C-u>lua _G.VSetSearch()<CR>/<C-r>=@/<CR><CR>]],
	{ silent = true, desc = "Search forward for selection" })
vim.keymap.set("x", "#", [[:<C-u>lua _G.VSetSearch()<CR>?<C-r>=@/<CR><CR>]],
	{ silent = true, desc = "Search backward for selection" })

-- :Rename newname  ── rename current file on disk.
vim.api.nvim_create_user_command("Rename", function(opts)
	local old = vim.fn.expand("%:t")
	vim.cmd("saveas " .. vim.fn.fnameescape(opts.args))
	vim.cmd("edit "   .. vim.fn.fnameescape(opts.args))
	vim.fn.delete(old)
end, { nargs = 1, desc = "Rename current file" })

-- :Stab  ── set tabstop = softtabstop = shiftwidth in one shot.
local function summarize_tabs()
	local parts = {
		"tabstop=" .. vim.bo.tabstop,
		"shiftwidth=" .. vim.bo.shiftwidth,
		"softtabstop=" .. vim.bo.softtabstop,
		vim.bo.expandtab and "expandtab" or "noexpandtab",
	}
	vim.api.nvim_echo({ { table.concat(parts, " "), "ModeMsg" } }, false, {})
end

vim.api.nvim_create_user_command("Stab", function()
	local n = tonumber(vim.fn.input("set tabstop = softtabstop = shiftwidth = "))
	if n and n > 0 then
		vim.bo.tabstop = n
		vim.bo.softtabstop = n
		vim.bo.shiftwidth = n
	end
	summarize_tabs()
end, { desc = "Set tab width" })
