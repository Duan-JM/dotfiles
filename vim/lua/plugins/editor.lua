return {
	{
		"tpope/vim-surround",
		lazy = false,
		priority = 1000,
		config = function()
			-- ...
		end,
	},
	{
		"tpope/vim-repeat",
		lazy = false,
		priority = 1000,
		config = function()
			-- ...
		end,
	},
	{
		"tpope/vim-commentary",
		lazy = false,
		priority = 1000,
		config = function()
			-- ...
		end,
	},
	{
		"mbbill/undotree",
		lazy = false,
		priority = 1000,
		config = function()
			-- ...
		end,
	},
	{
		"unblevable/quick-scope",
		lazy = false,
		priority = 1000,
		config = function()
			-- Set the keys for QuickScope highlight
			vim.g.qs_highlight_on_keys = { "f", "F", "t", "T" }

			-- Set up autocmd group for color scheme changes
			vim.api.nvim_create_augroup("qs_colors", { clear = true })
		end,
	},

	{
		"Raimondi/delimitMate",
		lazy = false,
		priority = 1000,
		config = function()
			-- Brackets Jump 智能补全括号和跳转
			-- 补全括号 shift+tab出来
		end,
	},
	{
		"andymass/vim-matchup",
		lazy = false,
		priority = 1000,
		config = function()
			-- ...
		end,
	},
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
			"MunifTanjim/nui.nvim",
			-- "3rd/image.nvim", -- Optional image support in preview window: See `# Preview Mode` for more information
		},
		keys = {
			{ "<leader>nt", "<cmd>Neotree<cr>", desc = "Open Neotree" },
		},
		window = {
			mappings = {
				["<bs>"] = "navigate_up",
				["."] = "set_root",
				["H"] = "toggle_hidden",
				["/"] = "fuzzy_finder",
				["D"] = "fuzzy_finder_directory",
				["#"] = "fuzzy_sorter", -- fuzzy sorting using the fzy algorithm
				-- ["D"] = "fuzzy_sorter_directory",
				["f"] = "filter_on_submit",
				["<c-x>"] = "clear_filter",
				["[g"] = "prev_git_modified",
				["]g"] = "next_git_modified",
				["o"] = { "show_help", nowait = false, config = { title = "Order by", prefix_key = "o" } },
				["oc"] = { "order_by_created", nowait = false },
				["od"] = { "order_by_diagnostics", nowait = false },
				["og"] = { "order_by_git_status", nowait = false },
				["om"] = { "order_by_modified", nowait = false },
				["on"] = { "order_by_name", nowait = false },
				["os"] = { "order_by_size", nowait = false },
				["ot"] = { "order_by_type", nowait = false },
				-- ['<key>'] = function(state) ... end,
			},
			fuzzy_finder_mappings = { -- define keymaps for filter popup window in fuzzy_finder_mode
				["<down>"] = "move_cursor_down",
				["<C-n>"] = "move_cursor_down",
				["<up>"] = "move_cursor_up",
				["<C-p>"] = "move_cursor_up",
				-- ['<key>'] = function(state, scroll_padding) ... end,
			},
		},
	},
}
