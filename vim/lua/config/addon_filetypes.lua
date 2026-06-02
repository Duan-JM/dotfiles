-- ===========================================================================
-- Filetype associations (modern vim.filetype API ── no more `autocmd!` chains)
-- ===========================================================================
vim.filetype.add({
	extension = {
		md       = "markdown",
		markdown = "markdown",
		ts       = "typescript",
		json     = "json",
		snippets = "snippets",
		vs       = "glsl",
		fs       = "glsl",
		swift    = "swift",
		vm       = "html",
		xtpl     = "html",
		ejs      = "html",
		conf     = "config",
		scss     = "scss.css",
		coffee   = "coffee",
		rss      = "xml",
		atom     = "xml",
		mako     = "mako",
		tex      = "tex",
	},
	pattern = {
		[".*%.html%.twig"] = "html.twig",
	},
})

-- Detect Perl in `.bat` files that begin with the `-*-Perl-*-` modeline.
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
	group = vim.api.nvim_create_augroup("user_ft_extra", { clear = true }),
	pattern = "*.bat",
	callback = function()
		local first = vim.fn.getline(1)
		if type(first) == "string" and first:match("%-%-%*%-Perl%-%*%-%-") then
			vim.bo.filetype = "perl"
		end
	end,
})
