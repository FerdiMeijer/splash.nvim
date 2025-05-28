local debug_log = function(msg)
	vim.notify("[splash.nvim] dbg:" .. tostring(msg), vim.log.levels.DEBUG)
end

local error_log = function(msg)
	vim.notify("[splash.nvim] err:" .. tostring(msg), vim.log.levels.ERROR)
end

local M = {
	debug_log = debug_log,
	error_log = error_log,
}

local get_vim_dimensions = function()
	local vim_width = vim.o.columns
	local vim_height = vim.o.lines
	debug_log("Resized dimensions: " .. vim_width .. "x" .. vim_height)
	return vim_width, vim_height
end

M.set_buffer_options = function(options)
	local bufnr = vim.api.nvim_get_current_buf()
	for key, value in pairs(options) do
		vim.bo[bufnr][key] = value
	end
end

M.set_window_options = function(options)
	local winid = vim.api.nvim_get_current_win()
	for key, value in pairs(options) do
		vim.wo[winid][key] = value
	end
end

M.get_window_options = function(options)
	local current = {}
	for key, _ in pairs(options) do
		current[key] = vim.wo[key]
	end
	return current
end

-- check if the splash screen should be shown,
-- do not show splash screen if the user is in insert mode or if there are no buffers open,
-- or command line arguments where passed, i.e. to open a specific file.
M.splash_screen_needed = function()
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

-- create a new buffer: not listed, scratch buffer
M.create_splash_buffer = function(lines)
	local splash_buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(splash_buf, 0, 0, false, lines)

	return splash_buf
end

M.create_splash_window = function(splash_width, splash_height, buffer, namespace, options)
	local vim_width, vim_height = get_vim_dimensions()

	local col = math.floor((vim_width - splash_width) / 2)
	local row = math.floor((vim_height - splash_height) / 2)
	local win_config = {
		relative = "editor",
		width = splash_width,
		height = splash_height,
		col = col,
		row = row,
		style = "minimal",
		focusable = false,
		noautocmd = true,
		border = options.border,
	}
	local splash_win = vim.api.nvim_open_win(buffer, true, win_config)

	vim.api.nvim_set_hl(namespace, "Normal", options.highlight)
	vim.api.nvim_win_set_hl_ns(splash_win, namespace)

	debug_log("Opened splash window ID: " .. splash_win)

	return splash_win
end

M.resize_splash_window = function(window)
	local vim_width, vim_height = get_vim_dimensions()
	local window_config = vim.api.nvim_win_get_config(window)
	window_config.col = math.floor((vim_width - window_config.width) / 2)
	window_config.row = math.floor((vim_height - window_config.height) / 2)

	vim.api.nvim_win_set_config(window, window_config)
end

M.close_splash = function(buffer, window, namespace)
	vim.api.nvim_buf_clear_namespace(buffer, namespace, 0, -1)
	vim.api.nvim_win_close(window, false)
	vim.api.nvim_buf_delete(buffer, {})
end

return M
