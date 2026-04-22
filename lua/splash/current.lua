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

	-- Save and hide statusline (delayed to override lualine and other statusline plugins)
	M.original_laststatus = vim.o.laststatus
	vim.schedule(function()
		vim.o.laststatus = 0
		log.debug("Hiding statusline (original laststatus: " .. M.original_laststatus .. ")")
	end)

	log.debug("Applying window: " .. M.window .. " options: " .. vim.inspect(overrides))
	set_window_options(M.window, overrides)
end

M.restore_win_opts = function()
	log.debug("Restoring window: " .. M.window .. " options: " .. vim.inspect(M.originals))
	set_window_options(M.window, M.originals)

	-- Restore statusline
	if M.original_laststatus then
		vim.o.laststatus = M.original_laststatus
		log.debug("Restored statusline (laststatus: " .. M.original_laststatus .. ")")
	end
end

return M
