return {
	{ -- lsp
		"neovim/nvim-lspconfig",
		lazy = false,
		dependencies = {
			"williamboman/mason.nvim",
			{
				"williamboman/mason-lspconfig.nvim",
				config = function()
					require("mason").setup()
					require("mason-lspconfig").setup({
						ensure_installed = { "pyright", "jdtls" },
					})
				end,
			},
		},
		config = function()
			util = require("lspconfig.util")
			function set_poetry_python()
				local handle = io.popen("poetry run which python")
				local path = handle:read("*a")
				path = path:match("^(.-)\n?$")
				handle:close()
				local clients = util.get_lsp_clients({
					bufnr = vim.api.nvim_get_current_buf(),
					name = "pyright",
				})
				for _, client in ipairs(clients) do
					if client.settings then
						client.settings.python =
							vim.tbl_deep_extend("force", client.settings.python, { pythonPath = path })
					else
						client.config.settings =
							vim.tbl_deep_extend("force", client.config.settings, { python = { pythonPath = path } })
					end
					-- debug
					-- print(vim.inspect(client.settings))
					client.notify("workspace/didChangeConfiguration", { settings = nil })
				end
			end
			require("lspconfig").pyright.setup({
				commands = {
					PyrightSetPoetrySetup = {
						set_poetry_python,
						description = "Use repo poetry python to setup pyright",
					},
				},
			})
			-- ✅ 配置 lua_ls，避免 vim 报 undefined
			require("lspconfig").lua_ls.setup({
				settings = {
					Lua = {
						diagnostics = {
							globals = { "vim" },
						},
						workspace = {
							checkThirdParty = false,
							library = {
								vim.env.VIMRUNTIME,
								require("lspconfig.util").path.join(vim.fn.stdpath("data"), "lazy", "nvim-lspconfig"),
							},
						},
						telemetry = { enable = false },
					},
				},
			})
		end,
	},
	{ -- java lsp
		"mfussenegger/nvim-jdtls",
		ft = "java",
		config = function()
			local config = {
				cmd = { "/opt/homebrew/bin/jdtls" },
				root_dir = require("jdtls.setup").find_root({ ".git", "mvnw", "gradlew" }),
			}
			require("jdtls").start_or_attach(config)
		end,
	},
	{ -- Autocompletion
		"hrsh7th/nvim-cmp",
		lazy = false,
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"L3MON4D3/LuaSnip",
			"saadparwaiz1/cmp_luasnip",
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-buffer",
		},
		config = function()
			local cmp = require("cmp")
			local luasnip = require("luasnip")
			luasnip.config.setup({})
			cmp.setup({
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				mapping = cmp.mapping.preset.insert({
					["<C-d>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<C-Space>"] = cmp.mapping.complete({}),
					["<CR>"] = cmp.mapping.confirm({
						behavior = cmp.ConfirmBehavior.Replace,
						select = true,
					}),
				}),
				sources = {
					{ name = "nvim_lsp" },
					{ name = "luasnip" },
					{ name = "path" },
					{ name = "buffer" },
				},
			})
		end,
	},
	{
		"mireq/luasnip-snippets",
		dependencies = { "L3MON4D3/LuaSnip" },
		init = function()
			-- Mandatory setup function
			require("luasnip_snippets.common.snip_utils").setup()
		end,
	},
}
