local utils = require("utils")
local plugin_dir = debug.getinfo(1, "S").source:sub(2):match("(.*/)")

local M = {}
M.window = nil
M.buffer = nil
M.namespace = nil

M.start_splash = function()
	if not M.options then
		utils.log_error("Please call require('splash').setup({}) to initialize configuration.")
		return M -- if the setup function was not called, we return early.
	end

	local lines = M.options.lines or utils.get_lines_from_file(M.options.file)
	local splash_width, splash_height = utils.get_dimensions(lines)

	M.buffer = utils.create_splash_buffer(lines)
	M.namespace = vim.api.nvim_create_namespace("splash")
	M.window = utils.create_splash_window(splash_width, splash_height, M.buffer, M.namespace, M.options.window)

	M.close_autocmd = vim.api.nvim_create_autocmd({ "ModeChanged", "CursorMoved", "TextChanged", "WinScrolled" }, {
		callback = function()
			utils.debug_log("auto_cmd: close window/buf " .. M.window .. "/" .. M.buffer)

			utils.close_splash(M.buffer, M.window, M.namespace)
			vim.api.nvim_del_autocmd(M.close_autocmd)
			vim.api.nvim_del_autocmd(M.resize_autocmd)
			M.window = nil
			M.buffer = nil
		end,
	})

	M.resize_autocmd = vim.api.nvim_create_autocmd("VimResized", {
		callback = function()
			utils.debug_log("resizing")
			utils.resize_splash_window(M.window)
		end,
	})
end

local defaults = {
	file = plugin_dir .. "skeleton.txt",
	window = {
		border = "none",
		highlight = { bg = "NONE", blend = 0 },
	},
	lines = { "Welcome to Neovim!" },
	enable_splash = utils.splash_screen_needed,
}

M.setup = function(opts)
	vim.opt.shortmess:append("I") -- disable default Neovim intro message

	M.options = vim.tbl_deep_extend("force", defaults, opts or {})
	if M.options.enable_splash() then
		M.start_splash()
	end
end

return M
