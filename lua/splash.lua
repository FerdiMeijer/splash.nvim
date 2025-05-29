local utils = require("utils")
local plugin_dir = debug.getinfo(1, "S").source:sub(2):match("(.*/)")

local M = {}
M.window = nil
M.current_win = nil
M.buffer = nil
M.namespace = nil

local current_window_options = {
	number = false,
	relativenumber = false,
	cursorline = false,
	cursorcolumn = false,
	signcolumn = "no",
	foldcolumn = "0",
	list = false,
}

M.start = function()
	if not M.options then
		utils.log_error("please call require('splash').setup({}) to initialize configuration.")
		return M -- if the setup function has not run, we return early.
	end

	M.current_win = vim.api.nvim_get_current_win()
	M.restore_win_opts = utils.get_window_options(M.current_win, current_window_options)
	utils.set_window_options(M.current_win, current_window_options)

	local lines = M.options.lines or utils.get_lines_from_file(M.options.file)
	local splash_width, splash_height = utils.get_dimensions(lines)

	M.buffer = utils.create_splash_buffer(lines)
	M.namespace = vim.api.nvim_create_namespace("splash")
	M.window = utils.create_splash_window(splash_width, splash_height, M.buffer, M.namespace, M.options.window)
	M.auto_cmds = {}
	M.setup_auto_cmds()
end

M.setup_auto_cmds = function()
	vim.api.nvim_create_autocmd("VimEnter", {
		callback = function()
			-- slight delay to allow lazy-loaded plugins to settle
			vim.defer_fn(function()
				for _, event in ipairs({ "ModeChanged", "CursorMoved" }) do --, "TextChanged", "WinScrolled"
					local auto_cmd = vim.api.nvim_create_autocmd(event, {
						callback = function()
							M.close(event)
						end,
					})

					table.insert(M.auto_cmds, auto_cmd)
				end

				table.insert(
					M.auto_cmds,
					vim.api.nvim_create_autocmd("VimResized", {
						callback = function()
							M.resize("VimResized")
						end,
					})
				)
			end, 100)
		end,
	})
end

M.close = function(event)
	utils.debug_log(event .. ": closing splash buf:" .. M.window .. " win:" .. M.buffer)
	utils.close_splash(M.buffer, M.window, M.namespace)

	-- remove autocommands
	for _, id in ipairs(M.auto_cmds) do
		vim.api.nvim_del_autocmd(id)
	end

	-- restore orginal windows' options
	utils.set_window_options(M.current_win, M.restore_win_opts)

	M.window = nil
	M.buffer = nil
	M.auto_cmds = nil
end

M.resize = function(event)
	if vim.v.vim_did_enter ~= 1 then
		utils.debug_log(event .. "startup is still running")
		return
	end

	if not M.ready_for_events then
		utils.debug_log(event .. "not ready")
		return
	end
	utils.debug_log(event .. " resizing splash")
	utils.resize_splash_window(M.window)
end

local defaults = {
	file = plugin_dir .. "dragon.txt",
	window = {
		border = "none",
		highlight = { bg = "NONE", blend = 0 },
	},
	enable_splash_fn = utils.splash_screen_needed,
}

M.setup = function(opts)
	M.options = vim.tbl_deep_extend("force", defaults, opts or {})
	if M.options.enable_splash_fn() then
		vim.opt.shortmess:append("I") -- disable default Neovim intro message
		M.start()
	end
end

return M
