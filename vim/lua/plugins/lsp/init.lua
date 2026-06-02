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
			"williamboman/mason-lspconfig.nvim",
			"hrsh7th/cmp-nvim-lsp",
		},
		config = function()
			require("mason-lspconfig").setup({
				ensure_installed       = { "pyright", "jdtls" },
				automatic_installation = true,
			})

			local caps = require("cmp_nvim_lsp").default_capabilities()

			-- Global default applied to every server.
			vim.lsp.config("*", { capabilities = caps })

			-- Enable pyright. jdtls is intentionally NOT enabled here ── it is
			-- started by nvim-jdtls (below) with project-aware settings.
			vim.lsp.enable("pyright")

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

					local prev, nxt
					if vim.diagnostic.jump then
						prev = function() vim.diagnostic.jump({ count = -1, float = true }) end
						nxt  = function() vim.diagnostic.jump({ count = 1,  float = true }) end
					else
						prev, nxt = vim.diagnostic.goto_prev, vim.diagnostic.goto_next
					end
					bmap("n", "[d", prev, "Prev diagnostic")
					bmap("n", "]d", nxt,  "Next diagnostic")
				end,
			})

			-- :PyrightSetPoetrySetup ── repoint pyright at the current poetry env.
			vim.api.nvim_create_user_command("PyrightSetPoetrySetup", function()
				local handle = io.popen("poetry run which python 2>/dev/null")
				if not handle then return end
				local path = (handle:read("*a") or ""):gsub("[\n\r]+$", "")
				handle:close()
				if path == "" then
					vim.notify("poetry returned no python path", vim.log.levels.WARN)
					return
				end
				for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0, name = "pyright" })) do
					client.settings = vim.tbl_deep_extend(
						"force",
						client.settings or {},
						{ python = { pythonPath = path } }
					)
					client.notify("workspace/didChangeConfiguration", { settings = client.settings })
				end
				vim.notify("pyright python -> " .. path)
			end, { desc = "Point pyright at poetry's python" })
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
