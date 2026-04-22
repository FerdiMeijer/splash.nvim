local logger = require("splash.logging")
local utils = require("splash.utils")
local current = require("splash.current")
local splash = require("splash.splash")
local auto = require("splash.auto")

local M = {}

---@class SplashHighlight
---@field bg? string Background color (e.g., "NONE", "#800000")
---@field fg? string Foreground color (e.g., "#ff0000")
---@field blend? number Transparency level (0-100)

---@class SplashWindow
---@field border? string|table Border style: "none", "single", "rounded", "double", "solid", "shadow", or custom border table
---@field highlight? SplashHighlight Highlight options for splash window

---@class SplashConfig
---@field lines? string[] Text lines to display (overrides file option if set)
---@field file? string Path to ASCII art file. Defaults to plugin's dragon.txt
---@field enable_logging? boolean Enable debug logging to splash_log buffer. Defaults to false
---@field enable_splash? boolean|function Whether to show splash screen. Can be boolean or function returning boolean. Defaults to function checking startup conditions
---@field remove_leading_whitespace? boolean Remove common leading whitespace from art for proper centering. Defaults to true
---@field window? SplashWindow Window appearance options

---@private
M.start = function()
	if not M.options then
		error("please call require('splash').setup({}) to initialize configuration.")

		return M -- if the setup function has not run, we return early.
	end

	logger.enabled = M.options.enable_logging
	logger.debug("starting splash setup with options: " .. vim.inspect(M.options))

	current.override_win_opts()

	splash.load(M.options)

	auto.setup_auto_close(function()
		splash.close()
		current.restore_win_opts()
	end)
	auto.setup_auto_resize(splash.resize)
end

local plugin_dir = debug.getinfo(1, "S").source:sub(2):match("(.*/)")
local defaults = {
	enable_logging = false,
	file = plugin_dir .. "../art/dragon.txt",
	window = {
		border = "none",
		highlight = { bg = "NONE", blend = 0 },
	},
	enable_splash = utils.splash_screen_needed,
	remove_leading_whitespace = true,
}

---Setup and initialize the splash screen plugin
---@param opts? SplashConfig Configuration options
M.setup = function(opts)
	opts = opts or {}

	-- Validate user options
	vim.validate({
		lines = { opts.lines, { "table", "nil" }, true },
		file = { opts.file, { "string", "nil" }, true },
		enable_logging = { opts.enable_logging, { "boolean", "nil" }, true },
		enable_splash = { opts.enable_splash, { "boolean", "function", "nil" }, true },
		remove_leading_whitespace = { opts.remove_leading_whitespace, { "boolean", "nil" }, true },
		window = { opts.window, { "table", "nil" }, true },
	})

	-- Validate window sub-options if provided
	if opts.window then
		vim.validate({
			border = { opts.window.border, { "string", "table", "nil" }, true },
			highlight = { opts.window.highlight, { "table", "nil" }, true },
		})

		-- Validate highlight sub-options if provided
		if opts.window.highlight then
			vim.validate({
				bg = { opts.window.highlight.bg, { "string", "nil" }, true },
				fg = { opts.window.highlight.fg, { "string", "nil" }, true },
				blend = { opts.window.highlight.blend, { "number", "nil" }, true },
			})
		end
	end

	M.options = vim.tbl_deep_extend("force", defaults, opts)

	if
		(type(M.options.enable_splash) == "function" and M.options.enable_splash())
		or (M.options.enable_splash == true)
	then
		vim.opt.shortmess:append("I")
		M.start()
	end
end

return M
