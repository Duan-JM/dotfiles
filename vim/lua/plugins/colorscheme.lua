return {
	{
		"flazz/vim-colorschemes",
		lazy = false,
		priority = 1000,
		config = function()
			--
		end,
	},
	{
		"sainnhe/edge",
		lazy = false,
		priority = 1000,
		dependences = {
			"sainnhe/edge",
		},
		config = function()
			vim.cmd([[colorscheme edge]])
		end,
	},
}
