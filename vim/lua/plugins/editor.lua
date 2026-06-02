return {
	-- Surround motions: cs"' / ds" / ysiw)
	{
		"tpope/vim-surround",
		event = "VeryLazy",
		dependencies = { "tpope/vim-repeat" },
	},

	-- Make many plugin actions repeatable with `.`
	{ "tpope/vim-repeat", event = "VeryLazy" },

	-- gcc / gc{motion} comments
	{ "tpope/vim-commentary", event = "VeryLazy" },

	-- Undo history visualiser
	{
		"mbbill/undotree",
		cmd  = { "UndotreeToggle", "UndotreeShow" },
		keys = { { "<leader>u", "<cmd>UndotreeToggle<cr>", desc = "Toggle undotree" } },
	},

	-- Highlight unique chars on f/F/t/T
	{
		"unblevable/quick-scope",
		event = { "BufReadPost", "BufNewFile" },
		init  = function()
			vim.g.qs_highlight_on_keys = { "f", "F", "t", "T" }
		end,
	},

	-- Treesitter-aware bracket auto-pair (replaces delimitMate)
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		opts = {
			check_ts  = true,
			fast_wrap = {},
		},
	},

	-- File explorer
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		cmd    = "Neotree",
		keys   = {
			{ "<leader>nt", "<cmd>Neotree filesystem reveal left<cr>", desc = "Open Neotree" },
		},
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons",
			"MunifTanjim/nui.nvim",
		},
		-- NOTE: this **must** live under `opts` so lazy.nvim actually forwards
		-- it to neo-tree. The previous config kept these tables at the spec
		-- root, so neo-tree silently used defaults.
		opts = {
			default_component_configs = {
				filesystem = {
					follow_current_file = { enabled = true, leave_dirs_open = false },
				},
			},
			window = {
				mappings = {
					["<bs>"]  = "navigate_up",
					["."]     = "set_root",
					["H"]     = "toggle_hidden",
					["/"]     = "fuzzy_finder",
					["D"]     = "fuzzy_finder_directory",
					["#"]     = "fuzzy_sorter",
					["f"]     = "filter_on_submit",
					["<c-x>"] = "clear_filter",
					["[g"]    = "prev_git_modified",
					["]g"]    = "next_git_modified",
					["o"]     = { "show_help", nowait = false, config = { title = "Order by", prefix_key = "o" } },
					["oc"]    = { "order_by_created",     nowait = false },
					["od"]    = { "order_by_diagnostics", nowait = false },
					["og"]    = { "order_by_git_status",  nowait = false },
					["om"]    = { "order_by_modified",    nowait = false },
					["on"]    = { "order_by_name",        nowait = false },
					["os"]    = { "order_by_size",        nowait = false },
					["ot"]    = { "order_by_type",        nowait = false },
				},
				fuzzy_finder_mappings = {
					["<C-n>"] = "move_cursor_down",
					["<C-p>"] = "move_cursor_up",
				},
			},
		},
	},
}
