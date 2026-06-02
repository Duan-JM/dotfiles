return {
	-- Statusline (replaces lightline + lighthaus-theme)
	{
		"nvim-lualine/lualine.nvim",
		event = "VeryLazy",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = {
			options = {
				icons_enabled        = true,
				theme                = "auto",
				component_separators = { left = "", right = "" },
				section_separators   = { left = "", right = "" },
				globalstatus         = true,
			},
			sections = {
				lualine_a = { "mode" },
				lualine_b = { "branch", "diff", "diagnostics" },
				lualine_c = { { "filename", path = 1 } },
				lualine_x = { "encoding", "fileformat", "filetype" },
				lualine_y = { "progress" },
				lualine_z = { "location" },
			},
		},
	},

	-- Rainbow brackets via treesitter (replaces luochen1990/rainbow)
	{
		"HiPhish/rainbow-delimiters.nvim",
		event = { "BufReadPost", "BufNewFile" },
		config = function()
			local rd = require("rainbow-delimiters")
			vim.g.rainbow_delimiters = {
				strategy = {
					[""]  = rd.strategy["global"],
					vim   = rd.strategy["local"],
				},
				query = {
					[""]  = "rainbow-delimiters",
					lua   = "rainbow-blocks",
				},
			}
		end,
	},

	-- Icons shared by lualine / neo-tree / aerial / telescope.
	{ "nvim-tree/nvim-web-devicons", lazy = true },
}
