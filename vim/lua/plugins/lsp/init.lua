return {
	{ -- LSP
		"neovim/nvim-lspconfig",
		lazy = false,
		dependencies = {
			"williamboman/mason.nvim",
			{
				"williamboman/mason-lspconfig.nvim",
				config = function()
					require("mason").setup()
					require("mason-lspconfig").setup({
						ensure_installed = { "jdtls", "ruff" },
					})
				end,
			},
		},
		config = function()
			local lspconfig = require("lspconfig")

			-- 自动获取 Poetry Python，如果不是 Poetry 项目返回 nil
			local function get_poetry_python()
				local handle = io.popen("poetry run which python 2>/dev/null")
				if not handle then
					return nil
				end
				local path = handle:read("*a")
				handle:close()
				path = path:match("^(.-)\n?$")
				if path == "" then
					return nil
				end
				return path
			end

			local function on_attach(client, bufnr)
				if client.name == "pyright" then
					local active_clients = vim.lsp.get_clients({ bufnr = bufnr })
					for _, c in ipairs(active_clients) do
						if c.name == "pyright" and c.id ~= client.id then
							-- vim.notify("Killing duplicate pyright (id=" .. c.id .. ")", vim.log.levels.DEBUG)
							c:stop()
						end
					end
				end
			end

			-- Pyright 配置
			lspconfig.pyright.setup({
				on_attach = on_attach,
				before_init = function(_, config)
					local python_path = get_poetry_python()
					if python_path then
						config.settings = config.settings or {}
						config.settings.python = config.settings.python or {}
						config.settings.python.pythonPath = python_path
					end
				end,
			})

			-- Lua LSP
			lspconfig.lua_ls.setup({
				settings = {
					Lua = {
						diagnostics = { globals = { "vim" } },
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

	{ -- Java LSP
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
					["<CR>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							if luasnip.expandable() then
								luasnip.expand()
							else
								cmp.confirm({ select = true })
							end
						else
							fallback()
						end
					end),
					["<Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_next_item()
						elseif luasnip.locally_jumpable(1) then
							luasnip.jump(1)
						else
							fallback()
						end
					end, { "i", "s" }),
					["<S-Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_prev_item()
						elseif luasnip.locally_jumpable(-1) then
							luasnip.jump(-1)
						else
							fallback()
						end
					end, { "i", "s" }),
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

	{ -- LuaSnip snippets
		"mireq/luasnip-snippets",
		dependencies = { "L3MON4D3/LuaSnip" },
		init = function()
			require("luasnip_snippets.common.snip_utils").setup()
		end,
	},
}
