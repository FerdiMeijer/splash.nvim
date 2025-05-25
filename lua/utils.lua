local M = {}

local debug_log = function(msg)
	vim.notify("[splash.nvim] dbg:" .. tostring(msg), vim.log.levels.DEBUG)
end

local error_log = function(msg)
	vim.notify("[splash.nvim] err:" .. tostring(msg), vim.log.levels.ERROR)
end

M.set_buffer_options = function(options)
	for key, value in pairs(options) do
		vim.bo[key] = value
	end
end

M.set_window_options = function(options)
	for key, value in pairs(options) do
		vim.wo[key] = value
	end
end

M.get_window_options = function(options)
	local current = {}
	for key, _ in pairs(options) do
		current[key] = vim.wo[key]
	end
	return current
end

M.enable_splash_screen = function()
	local result = not vim.opt.insertmode:get() and vim.fn.argc() == 0 and vim.fn.line2byte("$") ~= 1
		or vim.fn.empty(vim.fn.tabpagebuflist()) == 1
		or vim.fn.empty(vim.api.nvim_get_current_buf()) == 1

	debug_log("Should show splash screen: " .. tostring(result))
	return result
end

local open_file = function(file_path)
	debug_log("Opening file for splash screen: " .. file_path)
	local expanded_path = vim.fn.expand(file_path)
	local file, err = io.open(expanded_path, "r")
	if err then
		error_log("Error opening file for splash screen: " .. err)

		return M
	end
	if not file then
		return M -- if the file could not be opened, we return early.
	end

	return file
end

M.get_dimensions = function(lines)
	local splash_width = 0
	local splash_height = #lines
	for i, line in ipairs(lines) do
		splash_width = math.max(splash_width, #line)
	end

	debug_log("Splash screen dimensions: " .. splash_width .. "x" .. splash_height)
	return splash_width, splash_height
end

M.get_lines_from_file = function(file_path)
	local lines = {}
	local file = open_file(file_path)
	for line in file:lines() do
		table.insert(lines, line)
	end
	file:close()

	return lines
end

return M
