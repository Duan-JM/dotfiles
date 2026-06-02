return {
	-- Git signs in the sign column + hunk navigation/staging.
	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			signs = {
				add          = { text = "│" },
				change       = { text = "│" },
				delete       = { text = "_" },
				topdelete    = { text = "‾" },
				changedelete = { text = "~" },
				untracked    = { text = "┆" },
			},
			on_attach = function(bufnr)
				local gs = require("gitsigns")
				local function bmap(m, lhs, rhs, desc)
					vim.keymap.set(m, lhs, rhs, { buffer = bufnr, desc = desc })
				end
				bmap("n", "]c", function() gs.nav_hunk("next") end, "Next hunk")
				bmap("n", "[c", function() gs.nav_hunk("prev") end, "Prev hunk")
				bmap("n", "<leader>hs", gs.stage_hunk,   "Stage hunk")
				bmap("n", "<leader>hr", gs.reset_hunk,   "Reset hunk")
				bmap("n", "<leader>hp", gs.preview_hunk, "Preview hunk")
				bmap("n", "<leader>hb", function() gs.blame_line({ full = true }) end, "Blame line")
			end,
		},
	},

	-- Classic :Git / :Gdiffsplit / :GBrowse etc.
	{
		"tpope/vim-fugitive",
		cmd = {
			"Git", "G", "Gdiffsplit", "Gvdiffsplit", "Gread", "Gwrite",
			"Ggrep", "GMove", "GDelete", "GBrowse", "Gedit", "Gsplit",
		},
		keys = {
			{ "<leader>gs", "<cmd>Git<cr>",         desc = "Git status" },
			{ "<leader>gd", "<cmd>Gdiffsplit<cr>",  desc = "Git diff (split)" },
			{ "<leader>gb", "<cmd>Git blame<cr>",   desc = "Git blame" },
		},
	},
}
