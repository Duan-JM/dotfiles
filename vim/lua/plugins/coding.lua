return {
	{
		"SirVer/ultisnips",
		lazy = false,
		priority = 1000,
	},
	{
		"liuchengxu/vista.vim",
		ft = { "c", "cpp", "python", "markdown", "ts", "tsx" }, -- Lazy load for specified filetypes
		config = function()
			vim.g.snips_author = "Duan-JM"
			vim.g.snips_email = "vincent.duan95@outlook.com"
			vim.g.ultisnips_python_style = "goole"
			-- Optional: Add any custom configuration here for vista.vim
		end,
	},
}
