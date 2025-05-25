local utils = require("utils")
local plugin_dir = debug.getinfo(1, "S").source:sub(2):match("(.*/)")
local splash_buffer_options = {
	filetype = "splash",
	buftype = "nofile",
	modified = false,
	modifiable = true,
	bufhidden = "wipe",
	buflisted = false,
	swapfile = false,
}
local splash_window_options = {
	number = false,
	relativenumber = false,
	cursorline = false,
	cursorcolumn = false,
	signcolumn = "no",
	foldcolumn = "0",
	list = false,
}

local M = {}

M.options = {}

M.start_splash = function()
	if not M.options then
		utils.log_error("Please call require('splash').setup() to initialize configuration.")
		return M -- if the setup function was not called, we return early.
	end

	utils.set_buffer_options(splash_buffer_options)
	local restore = utils.get_window_options(splash_window_options)
	utils.set_window_options(splash_window_options)

	local buf = 0
	local win_height = vim.api.nvim_win_get_height(buf)
	local win_width = vim.api.nvim_win_get_width(buf)

	local lines = M.options.lines or utils.get_lines_from_file(M.options.file)
	local splash_height, splash_width = utils.get_dimensions(lines)

	local prepend_columns = math.floor(win_width / 2) - math.floor(splash_width / 2)

	for i, line in ipairs(lines) do
		if #line > win_width then
			line = line:sub(1, win_width - 1) -- truncate the line to fit the window width
		end

		if #line < win_width then
			-- if the line is shorter than the width of the window, we want to pad it with spaces.
			line = string.rep(" ", prepend_columns) .. line
		end

		lines[i] = line
	end

	local prepend_lines = math.floor(win_height / 2) - math.floor(splash_height / 2)
	for _ = 1, prepend_lines do
		table.insert(lines, 1, string.rep(" ", win_width)) -- add an empty line at the top
	end

	vim.api.nvim_buf_set_lines(buf, -1, -1, false, lines)
	-- vim.bo.modifiable = false

	-- whenever we leave this buffer/window, we want to delete it.
	vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave" }, {
		pattern = "<buffer>",
		callback = function()
			utils.set_window_options(restore)
			-- delete the splash buffer
			vim.cmd("bwipeout")
		end,
	})

	-- when i go to insert mode i want to leave this buffer and start a new one.
	vim.api.nvim_create_autocmd({ "InsertEnter", "StdinReadPre" }, {
		pattern = "<buffer>",
		callback = function()
			utils.set_window_options(restore)
			vim.cmd("stopinsert")
			vim.cmd("enew")
		end,
	})

	vim.api.nvim_create_autocmd("VimResized", {
		callback = function()
			utils.debug_log("Window resized, updating splash screen...")
			-- print("Resizing splash screen...")
			--M.start_splash(), -- re-run the splash screen when the window is resized
		end,
	})
end

local defaults = {
	file = plugin_dir .. "dragon.txt",
	message = "Welcome to Neovim!",
	-- Check if the splash screen should be shown,
	-- do not show it if the user is in insert mode or if there are no buffers open,
	-- or command line arguments where passed to open a specific file.
	enable_splash = utils.enable_splash_screen,
}

M.setup = function(opts)
	M.options = vim.tbl_deep_extend("force", defaults, opts or {})
	if M.options.enable_splash() then
		M.start_splash()
	end
end

return M
