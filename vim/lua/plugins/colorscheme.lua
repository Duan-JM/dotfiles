return {
	{
		"sainnhe/edge",
		lazy = false,
		priority = 1000,
		init = function()
			vim.g.edge_style              = "neon"
			vim.g.edge_better_performance = 1
		end,
		config = function()
			vim.cmd.colorscheme("edge")
		end,
	},
}
