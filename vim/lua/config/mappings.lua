-- ===========================================================================
-- Keymaps
-- ===========================================================================
local map = vim.keymap.set

-- Save current buffer.
map("n", "<leader>w", "<cmd>w<cr>", { desc = "Save buffer" })

-- Open this config.
map("n", "<leader>ev", "<cmd>tabe $MYVIMRC<cr>", { desc = "Edit init.lua" })

-- Reopen with a different encoding.
map("n", "<leader>eg", "<cmd>e ++enc=gbk<cr>",  { desc = "Reopen as GBK" })
map("n", "<leader>eu", "<cmd>e ++enc=utf8<cr>", { desc = "Reopen as UTF-8" })

-- Hex dump / restore.
map("n", "<leader>xd", "<cmd>%!xxd<cr>",    { desc = "Convert to hex" })
map("n", "<leader>xr", "<cmd>%!xxd -r<cr>", { desc = "Restore from hex" })

-- Conceal off.
map("n", "<leader>ll", "<cmd>set conceallevel=0<cr>", { desc = "Disable conceal" })

-- Tabs / windows.
map("n", "<leader>t",  "<cmd>tabe<cr>",     { desc = "New tab" })
map("n", "<leader>v",  "<cmd>vnew<cr>",     { desc = "New vertical split" })
map("n", "<leader>tq", "<cmd>tabclose<cr>", { desc = "Close tab" })
map("n", "<leader>tn", "<cmd>tabnext<cr>",  { desc = "Next tab" })

-- Add blank lines above/below the current line, count-aware.
map("n", "[<space>", ":<c-u>put! =repeat(nr2char(10), v:count1)<cr>'[",
	{ silent = true, desc = "Blank line above" })
map("n", "]<space>", ":<c-u>put  =repeat(nr2char(10), v:count1)<cr>",
	{ silent = true, desc = "Blank line below" })

-- Clear search highlight (and refresh diffs when relevant).
map("n", "<C-l>", function()
	vim.cmd("nohlsearch")
	if vim.fn.has("diff") == 1 then pcall(vim.cmd, "diffupdate") end
	vim.cmd("redraw!")
end, { desc = "Clear search highlight" })

-- Use display-line motion only when there is no count, so `5j` still jumps 5
-- *logical* lines (preserves jump list and relative-number behaviour).
map({ "n", "x" }, "j", function() return vim.v.count == 0 and "gj" or "j" end,
	{ expr = true, silent = true })
map({ "n", "x" }, "k", function() return vim.v.count == 0 and "gk" or "k" end,
	{ expr = true, silent = true })

-- Fix the previous spelling error without leaving insert mode.
map("i", "<C-l>", "<c-g>u<Esc>[s1z=`]a<c-g>u", { desc = "Auto-fix previous spelling" })
