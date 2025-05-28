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

	local win_width = vim.o.columns
	local win_height = vim.o.lines
	utils.debug_log("Window dimensions: " .. win_width .. "x" .. win_height)

	local lines = M.options.lines or utils.get_lines_from_file(M.options.file)
	local splash_width, splash_height = utils.get_dimensions(lines)
	utils.debug_log("Splash dimensions: " .. splash_width .. "x" .. splash_height)

	-- local col = math.floor((win_width - splash_width) / 2)
	-- local row = math.floor((win_height - splash_height) / 2)

	-- local win_config = {
	-- 	relative = "editor",
	-- 	width = splash_width,
	-- 	height = splash_height,
	-- 	col = col,
	-- 	row = row,
	-- 	style = "minimal",
	-- 	border = "none",
	-- 	focusable = true, -- make the splash window not focusable
	-- }
	--
	-- local splash_buf = vim.api.nvim_create_buf(false, true) -- create a new buffer: no file, scratch buffer
	-- vim.api.nvim_buf_set_lines(splash_buf, 0, 0, false, lines)
	--
	-- local splash_win = vim.api.nvim_open_win(splash_buf, true, win_config)
	-- utils.debug_log("Opened splash window ID: " .. splash_win)

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

	vim.api.nvim_buf_set_lines(0, -1, -1, false, lines)

	-- whenever we leave this buffer/window, we want to delete it.
	vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave" }, {
		pattern = "<buffer>",
		callback = function()
			utils.debug_log("Leaving splash screen buffer/window, restoring options...")
			-- vim.api.nvim_win_close(splash_win, true) -- close the splash window
			-- vim.api.nvim_buf_delete(splash_buf, { force = true }) -- delete the splash buffer

			utils.set_window_options(restore)
			-- delete the splash buffer
			--	vim.cmd("bwipeout")
		end,
	})

	-- when i go to insert mode i want to leave this buffer and start a new one.
	vim.api.nvim_create_autocmd({ "InsertEnter", "StdinReadPre" }, {
		pattern = "<buffer>",
		callback = function()
			-- vim.api.nvim_win_close(splash_win, true) -- close the splash window
			-- vim.api.nvim_buf_delete(splash_buf, { force = true }) -- delete the splash buffer

			utils.set_window_options(restore)
			vim.cmd("stopinsert")
			vim.cmd("enew")
		end,
	})

	vim.api.nvim_create_autocmd("VimResized", {
		callback = function()
			-- print("Resizing splash screen...")
			--M.start_splash(), -- re-run the splash screen when the window is resized
		end,
	})
end

local defaults = {
	file = plugin_dir .. "skeleton.txt",
	message = "Welcome to Neovim!",
	-- Check if the splash screen should be shown,
	-- do not show it if the user is in insert mode or if there are no buffers open,
	-- or command line arguments where passed, i.e. to open a specific file.
	enable_splash = utils.enable_splash_screen,
}

M.setup = function(opts)
	vim.opt.shortmess:append("I") -- disable default Neovim intro message

	M.options = vim.tbl_deep_extend("force", defaults, opts or {})
	if M.options.enable_splash() then
		M.start_splash()
	end
end

return M
