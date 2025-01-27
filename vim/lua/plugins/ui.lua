return {
	{
		"itchyny/lightline.vim",
		lazy = false,
		priority = 1000,
		dependencies = {
			"lighthaus-theme/vim-lighthaus",
		},
		config = function()
			vim.g.lightline = {
				colorscheme = "lighthaus",
				active = {
					left = { { "mode", "paste" }, { "filename", "modified" } },
					right = {
						{ "lineinfo" },
						{ "percent" },
						{ "linter_checking", "linter_errors", "linter_warnings", "linter_infos", "linter_ok" },
					},
				},
				separator = {
					left = "",
					right = "",
				},
				-- component_function = {
				-- 	-- gitbranch= 'FugitiveHead',
				-- },
				component_type = {
					readonly = "error",
					linter_infos = "right",
					linter_warnings = "warning",
					linter_errors = "error",
					linter_ok = "right",
				},
				enable = {
					statusline = 1,
					tabline = 0,
				},
			}
		end,
	},
	{
		"luochen1990/rainbow",
		lazy = false,
		priority = 1000,
		config = function()
			vim.g.rainbow_active = 1
		end,
	},
}
