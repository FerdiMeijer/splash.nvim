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

return M
