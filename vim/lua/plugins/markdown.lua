return {
	{
		"ice345/markdown-table-wrap.nvim",
		ft = { "markdown", "quarto", "rmd", "rmarkdown" },
		keys = {
			{ "<leader>mr", "<cmd>MarkdownTableToggleReader<cr>", desc = "Toggle Markdown table reader" },
			{ "<leader>mi", "<cmd>MarkdownTableToggleInline<cr>", desc = "Toggle Markdown table inline view" },
			{ "<leader>mf", "<cmd>MarkdownTableFloatPreview<cr>", desc = "Preview Markdown table in float" },
		},
		opts = {},
	},
}
