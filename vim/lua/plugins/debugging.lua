return {
	-- Install Delve through Mason so Go debugging works without a separate
	-- system package.
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		event = "VeryLazy",
		dependencies = { "williamboman/mason.nvim" },
		opts = {
			ensure_installed = { "delve" },
			run_on_start = true,
		},
	},

	-- Debug Adapter Protocol client with Go/Delve defaults.
	{
		"mfussenegger/nvim-dap",
		ft = "go",
		keys = {
			{
				"<F5>",
				function()
					require("dap").continue()
				end,
				desc = "Debug: start / continue",
			},
			{
				"<F10>",
				function()
					require("dap").step_over()
				end,
				desc = "Debug: step over",
			},
			{
				"<F11>",
				function()
					require("dap").step_into()
				end,
				desc = "Debug: step into",
			},
			{
				"<F12>",
				function()
					require("dap").step_out()
				end,
				desc = "Debug: step out",
			},
			{
				"<leader>db",
				function()
					require("dap").toggle_breakpoint()
				end,
				desc = "Debug: toggle breakpoint",
			},
			{
				"<leader>dB",
				function()
					require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
				end,
				desc = "Debug: conditional breakpoint",
			},
			{
				"<leader>dr",
				function()
					require("dap").repl.open()
				end,
				desc = "Debug: open REPL",
			},
			{
				"<leader>dt",
				function()
					require("dap-go").debug_test()
				end,
				desc = "Debug: Go test",
			},
			{
				"<leader>dx",
				function()
					require("dap").terminate()
				end,
				desc = "Debug: terminate",
			},
		},
		dependencies = {
			"leoluz/nvim-dap-go",
		},
		config = function()
			local mason_dlv = vim.fn.stdpath("data") .. "/mason/bin/dlv"
			local dlv_path = vim.uv.fs_stat(mason_dlv) and mason_dlv or "dlv"
			require("dap-go").setup({
				delve = { path = dlv_path },
			})

			vim.fn.sign_define("DapBreakpoint", {
				text = "B",
				texthl = "DiagnosticError",
				linehl = "",
				numhl = "",
			})
			vim.fn.sign_define("DapBreakpointCondition", {
				text = "C",
				texthl = "DiagnosticWarn",
				linehl = "",
				numhl = "",
			})
			vim.fn.sign_define("DapStopped", {
				text = ">",
				texthl = "DiagnosticInfo",
				linehl = "Visual",
				numhl = "",
			})
		end,
	},
}
