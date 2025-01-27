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
	{
		"yetone/avante.nvim",
		event = "VeryLazy",
		lazy = false,
		version = false, -- set this to "*" if you want to always pull the latest change, false to update on release
		opts = {
			provider = "azure",
			auto_suggestions_provider = "azure",
			azure = {
				endpoint = "https://daredevilopenapi.openai.azure.com/",
				deployment = "devapi4o",
				model = "gpt-4o",
				api_version = "2024-02-15-preview",
				temperature = 0,
				max_tokens = 4096,
			},
		},
		-- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
		build = "make",
		-- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows
		dependencies = {
			"stevearc/dressing.nvim",
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
			--- The below dependencies are optional,
			"hrsh7th/nvim-cmp", -- autocompletion for avante commands and mentions
			"nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
			"zbirenbaum/copilot.lua", -- for providers='copilot'
			{
				-- support for image pasting
				"HakonHarnes/img-clip.nvim",
				event = "VeryLazy",
				opts = {
					-- recommended settings
					default = {
						embed_image_as_base64 = false,
						prompt_for_file_name = false,
						drag_and_drop = {
							insert_mode = true,
						},
						-- required for Windows users
						use_absolute_path = true,
					},
				},
			},
			{
				-- Make sure to set this up properly if you have lazy=true
				"MeanderingProgrammer/render-markdown.nvim",
				opts = {
					file_types = { "markdown", "Avante" },
				},
				ft = { "markdown", "Avante" },
			},
		},
	},
}
