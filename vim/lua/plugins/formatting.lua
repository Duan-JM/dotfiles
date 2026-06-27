return {
	"stevearc/conform.nvim",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local conform = require("conform")
		local python_env = require("config.python_env")

		local function python_formatter(name)
			return function(bufnr)
				local root = python_env.root(vim.api.nvim_buf_get_name(bufnr))
				return python_env.formatter_command(root, name)
			end
		end

		conform.setup({
			formatters_by_ft = {
				javascript = { "prettier" },
				typescript = { "prettier" },
				javascriptreact = { "prettier" },
				typescriptreact = { "prettier" },
				svelte = { "prettier" },
				css = { "prettier" },
				html = { "prettier" },
				json = { "prettier" },
				yaml = { "prettier" },
				markdown = { "prettier" },
				graphql = { "prettier" },
				lua = { "stylua" },
				python = { "isort", "black" },
				java = { "google-java-format" },
				rust = { "rustfmt" },
			},
			format_on_save = {
				-- These options will be passed to conform.format()
				timeout_ms = 3000,
				lsp_format = "fallback",
			},
			formatters = {
				black = python_formatter("black"),
				isort = python_formatter("isort"),
			},
		})
	end,
}
