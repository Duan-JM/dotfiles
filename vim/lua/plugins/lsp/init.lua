return {
	-- Mason: external-tool installer (LSPs, formatters, linters)
	{
		"williamboman/mason.nvim",
		cmd   = "Mason",
		build = ":MasonUpdate",
		opts  = {},
	},

	-- LSP configuration ── uses the modern `vim.lsp.config` / `vim.lsp.enable`
	-- API (nvim ≥ 0.11). nvim-lspconfig only provides the per-server defaults
	-- (cmd / filetypes / root_markers); we just augment them with capabilities
	-- and enable the servers we want.
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"williamboman/mason.nvim",
			"hrsh7th/cmp-nvim-lsp",
		},
		config = function()
			local caps = require("cmp_nvim_lsp").default_capabilities()
			local python_env = require("config.python_env")

			-- Global default applied to every server.
			vim.lsp.config("*", { capabilities = caps })

			local function executable(name)
				return vim.fn.exepath(name) ~= ""
			end

			if executable("pyright-langserver") then
				vim.lsp.config("pyright", {
					cmd = { vim.fn.exepath("pyright-langserver"), "--stdio" },
					on_new_config = function(config, root_dir)
						local python = python_env.python(root_dir)
						if not python then return end
						config.settings = vim.tbl_deep_extend("force", config.settings or {}, {
							python = { pythonPath = python },
						})
					end,
				})
				vim.lsp.enable("pyright")
			else
				vim.api.nvim_create_autocmd("FileType", {
					group = vim.api.nvim_create_augroup("user_lsp_missing_pyright", { clear = true }),
					pattern = "python",
					callback = function()
						vim.notify("pyright-langserver not on PATH; install pyright for Python LSP",
							vim.log.levels.WARN)
					end,
				})
			end

			if executable("rust-analyzer") then
				vim.lsp.enable("rust_analyzer")
			else
				vim.api.nvim_create_autocmd("FileType", {
					group = vim.api.nvim_create_augroup("user_lsp_missing_rust_analyzer", { clear = true }),
					pattern = "rust",
					callback = function()
						vim.notify("rust-analyzer not on PATH; install it for Rust LSP",
							vim.log.levels.WARN)
					end,
				})
			end

			-- Buffer-local mappings on LSP attach.
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("user_lsp_attach", { clear = true }),
				callback = function(ev)
					local function bmap(mode, lhs, rhs, desc)
						vim.keymap.set(mode, lhs, rhs, { buffer = ev.buf, desc = desc })
					end
					bmap("n", "gd",         vim.lsp.buf.definition,     "LSP: goto definition")
					bmap("n", "gD",         vim.lsp.buf.declaration,    "LSP: goto declaration")
					bmap("n", "gr",         vim.lsp.buf.references,     "LSP: references")
					bmap("n", "gi",         vim.lsp.buf.implementation, "LSP: implementation")
					bmap("n", "K",          vim.lsp.buf.hover,          "LSP: hover")
					bmap("n", "<leader>rn", vim.lsp.buf.rename,         "LSP: rename")
					bmap("n", "<leader>ca", vim.lsp.buf.code_action,    "LSP: code action")

					local prev = function() vim.diagnostic.jump({ count = -1, float = true }) end
					local nxt  = function() vim.diagnostic.jump({ count = 1,  float = true }) end
					bmap("n", "[d", prev, "Prev diagnostic")
					bmap("n", "]d", nxt,  "Next diagnostic")
				end,
			})
		end,
	},

	-- Java LSP. Resolve the binary via PATH so brew or mason both work.
	{
		"mfussenegger/nvim-jdtls",
		ft = "java",
		config = function()
			local jdtls_cmd = vim.fn.exepath("jdtls")
			if jdtls_cmd == "" then
				vim.notify("jdtls not on PATH; install via :Mason or brew",
					vim.log.levels.WARN)
				return
			end
			require("jdtls").start_or_attach({
				cmd      = { jdtls_cmd },
				root_dir = require("jdtls.setup").find_root({ ".git", "mvnw", "gradlew" }),
			})
		end,
	},

	-- Autocompletion (LSP + snippets + buffer + path)
	{
		"hrsh7th/nvim-cmp",
		event = { "InsertEnter", "CmdlineEnter" },
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			{
				"L3MON4D3/LuaSnip",
				dependencies = { "mireq/luasnip-snippets" },
				config = function()
					require("luasnip").config.setup({})
					require("luasnip_snippets.common.snip_utils").setup()
				end,
			},
			"saadparwaiz1/cmp_luasnip",
		},
		config = function()
			local cmp     = require("cmp")
			local luasnip = require("luasnip")
			cmp.setup({
				snippet = {
					expand = function(args) luasnip.lsp_expand(args.body) end,
				},
				mapping = cmp.mapping.preset.insert({
					["<C-d>"]     = cmp.mapping.scroll_docs(-4),
					["<C-f>"]     = cmp.mapping.scroll_docs(4),
					["<C-Space>"] = cmp.mapping.complete(),
					["<CR>"]      = cmp.mapping.confirm({
						behavior = cmp.ConfirmBehavior.Replace,
						select   = true,
					}),
				}),
				sources = cmp.config.sources({
					{ name = "nvim_lsp" },
					{ name = "luasnip" },
				}, {
					{ name = "path" },
					{ name = "buffer" },
				}),
			})
		end,
	},
}
