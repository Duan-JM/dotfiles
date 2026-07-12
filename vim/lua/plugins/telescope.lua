return {
	{
		"nvim-telescope/telescope.nvim",
		cmd = "Telescope",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons",
			{
				"nvim-telescope/telescope-fzf-native.nvim",
				build = "make",
				cond  = function()
					local plugin = vim.fn.stdpath("data") .. "/lazy/telescope-fzf-native.nvim"
					return vim.fn.glob(plugin .. "/build/libfzf.*") ~= ""
						or vim.fn.executable("make") == 1
				end,
			},
		},
		keys = {
			{ "<C-p>",      "<cmd>Telescope find_files<cr>",               desc = "Find files" },
			{ "<leader>ff", "<cmd>Telescope find_files<cr>",               desc = "Find files" },
			{ "<leader>fg", "<cmd>Telescope live_grep<cr>",                desc = "Live grep" },
			{ "<leader>fb", "<cmd>Telescope buffers<cr>",                  desc = "Buffers" },
			{ "<leader>fh", "<cmd>Telescope help_tags<cr>",                desc = "Help tags" },
			{ "<leader>fl", "<cmd>Telescope current_buffer_fuzzy_find<cr>", desc = "Search lines in buffer" },
			{ "<leader>ft", "<cmd>Telescope treesitter<cr>",               desc = "Treesitter symbols" },
			{ "<leader>fr", "<cmd>Telescope oldfiles<cr>",                 desc = "Recent files" },
		},
		config = function()
			local telescope = require("telescope")
			telescope.setup({
				defaults = {
					mappings = {
						i = {
							["<C-j>"] = "move_selection_next",
							["<C-k>"] = "move_selection_previous",
							["<C-]>"] = "select_tab",
							["<C-x>"] = "select_horizontal",
							["<C-v>"] = "select_vertical",
						},
					},
				},
			})
			pcall(telescope.load_extension, "fzf")
		end,
	},
}
