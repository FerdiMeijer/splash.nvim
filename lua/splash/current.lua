local log = require("splash.logging")
local M = {}

M.window = {}
M.originals = {}

local overrides = {
	number = false,
	relativenumber = false,
	cursorline = false,
	cursorcolumn = false,
	signcolumn = "no",
	foldcolumn = "0",
	list = false,
}

local set_window_options = function(window, options)
	for key, value in pairs(options) do
		vim.wo[window][key] = value
	end
end

local get_window_options = function(window, options)
	local current = {}
	for key, _ in pairs(options) do
		current[key] = vim.wo[window][key]
	end
	return current
end

M.override_win_opts = function()
	M.window = vim.api.nvim_get_current_win()
	M.originals = get_window_options(M.window, overrides)
	set_window_options(M.window, overrides)
end

M.restore_win_opts = function()
	set_window_options(M.window, M.originals)
end

local get_vim_dimensions = function()
	local vim_width = vim.o.columns
	local vim_height = vim.o.lines

	return vim_width, vim_height
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
		border = options.border,
	}
	local splash_win = vim.api.nvim_open_win(buffer, true, win_config)

	vim.api.nvim_set_hl(namespace, "Normal", options.highlight)
	vim.api.nvim_win_set_hl_ns(splash_win, namespace)

	log.debug("opened splash window: " .. splash_win)

	return splash_win
end

M.load = function(splash, options)
	M.namespace = vim.api.nvim_create_namespace("splash")
	M.window = create_splash_window(splash.width, splash.height, splash.buffer, M.namespace, options.window)
end

return M
