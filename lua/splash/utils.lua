local M = {}

-- check if the splash screen should be shown,
M.splash_screen_needed = function()
	return vim.fn.argc() == 0 -- No file arguments
		and not vim.opt.insertmode:get() -- Not in insert mode
		and vim.fn.line2byte("$") == -1 -- Current buffer is empty
end

return M
