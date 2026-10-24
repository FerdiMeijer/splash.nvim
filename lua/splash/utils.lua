local log = require("splash.logging")
local M = {}

-- check if the splash screen should be shown
M.splash_screen_needed = function()
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local has_buffer_content = #lines > 1 or (lines[1] or "") ~= ""
	local has_stdin_arg = vim.tbl_contains(vim.v.argv, "-")
	local is_embedded = vim.tbl_contains(vim.v.argv, "--embed")
	local uv = vim.uv or vim.loop
	local stdin_kind = uv and uv.guess_handle(0) or "unavailable"
	local stdin_is_redirected = uv ~= nil and stdin_kind ~= "tty"
	local insertmode = vim.opt.insertmode:get()
	local argc = vim.fn.argc()

	local result = not insertmode
		and argc == 0
		and not has_stdin_arg
		and not is_embedded
		and not stdin_is_redirected
		and not has_buffer_content

	log.debug("splash_screen_needed: " .. vim.inspect({
		result = result,
		insertmode = insertmode,
		argc = argc,
		argv = vim.v.argv,
		has_stdin_arg = has_stdin_arg,
		is_embedded = is_embedded,
		stdin_kind = stdin_kind,
		stdin_is_redirected = stdin_is_redirected,
		buffer_line_count = #lines,
		has_buffer_content = has_buffer_content,
	}))

	return result
end

return M
