return {
	-- Code outline / symbol navigator (replaces vista.vim)
	{
		"stevearc/aerial.nvim",
		cmd  = { "AerialToggle", "AerialOpen", "AerialNavToggle" },
		keys = {
			{ "<leader>o", "<cmd>AerialToggle!<cr>", desc = "Toggle outline (Aerial)" },
		},
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"nvim-tree/nvim-web-devicons",
		},
		opts = {
			backends = { "treesitter", "lsp", "markdown", "man" },
			layout   = { default_direction = "right" },
		},
	},
}
