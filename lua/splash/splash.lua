local log = require("splash.logging")
local animation = require("splash.animation")

local M = {}

local get_dimensions = function(lines)
	local splash_width = 0
	local splash_height = #lines
	for _, line in ipairs(lines) do
		splash_width = math.max(splash_width, #line)
	end

	log.debug("splash dimensions: " .. splash_width .. "x" .. splash_height)

	return splash_width, splash_height
end

local get_lines_from_file = function(file_path)
	log.debug("reading file for splash screen: " .. file_path)
	local expanded_path = vim.fs.normalize(file_path)

	local ok, lines = pcall(vim.fn.readfile, expanded_path)
	if not ok then
		local msg = "error reading file '" .. file_path .. "': " .. lines
		log.err(msg)
		error(msg)
	end

	return lines
end

-- create a new buffer: not listed, scratch buffer
local create_splash_buffer = function(lines)
	local splash_buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(splash_buf, 0, 0, false, lines)

	return splash_buf
end

local get_vim_dimensions = function()
	local vim_width = vim.o.columns
	local vim_height = vim.o.lines

	return vim_width, vim_height
end

local remove_leading_whitespace = function(lines)
	local min_leading = math.huge
	for _, line in ipairs(lines) do
		local leading = line:match("^(%s*)")
		min_leading = math.min(min_leading, #leading)
	end
	log.debug("minimum leading whitespace: " .. min_leading)
	if min_leading == 0 or min_leading == math.huge then
		return lines
	end
	local trimmed = {}
	for i, line in ipairs(lines) do
		trimmed[i] = line:sub(min_leading + 1)
	end
	log.debug("trimmed lines: " .. vim.inspect(trimmed))
	return trimmed
end

local create_splash_window = function(splash_width, splash_height, buffer, namespace, options)
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
		border = options.border or "none",
	}
	local splash_win = vim.api.nvim_open_win(buffer, false, win_config)

	vim.api.nvim_set_hl(namespace, "Normal", options.highlight)
	vim.api.nvim_win_set_hl_ns(splash_win, namespace)

	log.debug("opened splash window: " .. splash_win)

	return splash_win
end

M.load = function(options)
	log.debug("loading splash")
	local lines = options.lines or get_lines_from_file(options.file)
	if options.remove_leading_whitespace then
		log.debug("removing leading whitespace from splash lines")
		lines = remove_leading_whitespace(lines)
	end

	local splash_width, splash_height = get_dimensions(lines)
	M.width = splash_width
	M.height = splash_height
	M.lines = lines -- Store lines for animation
	M.buffer = create_splash_buffer(lines)

	M.namespace = vim.api.nvim_create_namespace("splash")
	M.window = create_splash_window(M.width, M.height, M.buffer, M.namespace, options.window)

	-- Start animation if enabled
	if options.animation and options.animation.enabled then
		M.animation_timer = animation.start(
			M.buffer,
			M.window,
			M.namespace,
			lines,
			options.animation,
			options.window.highlight
		)
	end
end

M.skip_animation = function()
	if M.animation_timer then
		log.debug("skipping animation")
		animation.stop(M.animation_timer)
		M.animation_timer = nil

		-- Ensure final state is correct
		if M.buffer and vim.api.nvim_buf_is_valid(M.buffer) and M.lines then
			vim.api.nvim_buf_set_lines(M.buffer, 0, -1, false, M.lines)
		end
	end
end

M.resize = function()
	-- Check if window is still valid
	if not M.window or not vim.api.nvim_win_is_valid(M.window) then
		log.debug("cannot resize: splash window is not valid")
		return
	end

	log.debug("resizing splash")
	local vim_width, vim_height = get_vim_dimensions()
	local window_config = vim.api.nvim_win_get_config(M.window)
	window_config.col = math.floor((vim_width - window_config.width) / 2)
	window_config.row = math.floor((vim_height - window_config.height) / 2)
	vim.api.nvim_win_set_config(M.window, window_config)
end
M.close = function()
	log.debug("closing splash")

	-- Stop animation if running
	if M.animation_timer then
		animation.stop(M.animation_timer)
		M.animation_timer = nil
	end

	-- Clear namespace if buffer is valid
	if M.buffer and vim.api.nvim_buf_is_valid(M.buffer) then
		vim.api.nvim_buf_clear_namespace(M.buffer, M.namespace, 0, -1)
	end

	-- Close window if valid
	if M.window and vim.api.nvim_win_is_valid(M.window) then
		vim.api.nvim_win_close(M.window, false)
	end

	-- Delete buffer if valid
	if M.buffer and vim.api.nvim_buf_is_valid(M.buffer) then
		vim.api.nvim_buf_delete(M.buffer, {})
	end

	-- Always cleanup state
	M.buffer = nil
	M.window = nil
	M.namespace = nil
	M.lines = nil
	M.animation_timer = nil
end
return M
