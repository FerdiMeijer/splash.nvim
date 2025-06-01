local logger = require("splash.logging")
local utils = require("splash.utils")
local current = require("splash.current")
local splash = require("splash.splash")
local auto = require("splash.auto")

local M = {}

M.start = function()
	if not M.options then
		error("please call require('splash').setup({}) to initialize configuration.")

		return M -- if the setup function has not run, we return early.
	end

	logger.enabled = M.options.enable_logging

	current.override_win_opts()

	splash.load(M.options)

	auto.setup_close(function()
		splash.close()
		current.restore_win_opts()
	end)
	auto.setup_resize(splash.resize)
end

local plugin_dir = debug.getinfo(1, "S").source:sub(2):match("(.*/)")
local defaults = {
	enable_logging = false,
	file = plugin_dir .. "../art/dragon.txt",
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
