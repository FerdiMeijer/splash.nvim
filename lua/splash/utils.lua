local M = {}

-- check if the splash screen should be shown,
-- do not show splash screen if:
-- - the user is in insert mode
-- - if there are no buffers open,
-- - when command line arguments were passed, i.e. to open a specific file.
M.splash_screen_needed = function()
	local result = not vim.opt.insertmode:get() and vim.fn.argc() == 0 and vim.fn.line2byte("$") ~= 1
		or vim.fn.empty(vim.fn.tabpagebuflist()) == 1
		or vim.fn.empty(vim.api.nvim_get_current_buf()) == 1

	return result
end

return M
