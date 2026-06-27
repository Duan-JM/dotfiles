local M = {}

local root_markers = {
	"pyproject.toml",
	"poetry.lock",
	"uv.lock",
	"requirements.txt",
	"setup.py",
	"setup.cfg",
	".git",
}

local function executable(path)
	return path and path ~= "" and vim.fn.executable(path) == 1
end

function M.root(filename)
	filename = filename or vim.api.nvim_buf_get_name(0)
	if filename == "" then
		return vim.fn.getcwd()
	end
	return vim.fs.root(filename, root_markers) or vim.fs.dirname(filename)
end

function M.is_poetry_project(root_dir)
	if not root_dir or root_dir == "" then return false end
	if vim.fn.filereadable(root_dir .. "/poetry.lock") == 1 then
		return true
	end

	local pyproject = root_dir .. "/pyproject.toml"
	if vim.fn.filereadable(pyproject) ~= 1 then
		return false
	end

	local ok, lines = pcall(vim.fn.readfile, pyproject, "", 200)
	if not ok then return false end
	for _, line in ipairs(lines) do
		if line:match("^%s*%[tool%.poetry%]") then
			return true
		end
	end
	return false
end

function M.venv_bin(root_dir, name)
	if not root_dir or root_dir == "" then return nil end
	local path = root_dir .. "/.venv/bin/" .. name
	if executable(path) then
		return path
	end
	return nil
end

function M.python(root_dir)
	local venv_python = M.venv_bin(root_dir, "python")
	if venv_python then
		return venv_python
	end

	if vim.fn.exepath("poetry") ~= "" and M.is_poetry_project(root_dir) then
		local result = vim.system(
			{ "poetry", "env", "info", "--executable" },
			{ cwd = root_dir, text = true }
		):wait()
		if result.code == 0 then
			local python = (result.stdout or ""):gsub("[\n\r]+$", "")
			if executable(python) then
				return python
			end
		end
	end

	return nil
end

function M.formatter_command(root_dir, name)
	local local_tool = M.venv_bin(root_dir, name)
	if local_tool then
		return { command = local_tool }
	end

	if vim.fn.exepath("poetry") ~= "" and M.is_poetry_project(root_dir) then
		return {
			command = "poetry",
			prepend_args = { "run", name },
		}
	end

	return { command = name }
end

return M
