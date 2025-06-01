local debug_log = function(msg)
	vim.notify("[splash.nvim] dbg:" .. tostring(msg), vim.log.levels.DEBUG)
end

local error_log = function(msg)
	vim.notify("[splash.nvim] err:" .. tostring(msg), vim.log.levels.ERROR)
end

local M = {
	debug_log = debug_log,
	error_log = error_log,
}

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

M.setup_auto_cmds = function(close_splash_fn, resize_splash_fn)
	M.auto_cmds = {}
	vim.api.nvim_create_autocmd("VimEnter", {
		callback = function()
			-- slight delay to allow other plugins to settle
			vim.defer_fn(function()
				for _, event in ipairs({ "ModeChanged", "CursorMoved" }) do --, "TextChanged", "WinScrolled"
					local auto_cmd = vim.api.nvim_create_autocmd(event, {
						callback = function()
							close_splash_fn()

							-- cleanup autocommands
							for _, id in ipairs(M.auto_cmds) do
								vim.api.nvim_del_autocmd(id)
							end
						end,
					})

					table.insert(M.auto_cmds, auto_cmd)
				end

				local resize_auto_cmd = vim.api.nvim_create_autocmd("VimResized", {
					callback = function()
						resize_splash_fn()
					end,
				})

				table.insert(M.auto_cmds, resize_auto_cmd)
			end, 100)
		end,
	})
end

return M
