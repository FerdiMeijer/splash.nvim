local M = {}

M.auto_cmds = {}

M.setup_auto_close = function(callback, skip_animation_callback)
	vim.api.nvim_create_autocmd("VimEnter", {
		callback = function()
			-- Schedule in next event loop for safety
			vim.schedule(function()
				for _, event in ipairs({ "ModeChanged", "CursorMoved", "BufEnter" }) do
					local auto_cmd = vim.api.nvim_create_autocmd(event, {
						callback = function()
							-- Skip animation immediately on user interaction
							if skip_animation_callback then
								skip_animation_callback()
							end

							callback()

							-- auto cleanup auto_cmds
							for _, id in ipairs(M.auto_cmds) do
								vim.api.nvim_del_autocmd(id)
							end

							M.auto_cmds = {}
						end,
					})

					table.insert(M.auto_cmds, auto_cmd)
				end
			end)
		end,
	})
end

M.setup_auto_resize = function(callback)
	local resize_auto_cmd = vim.api.nvim_create_autocmd("VimResized", {
		callback = callback,
	})

	table.insert(M.auto_cmds, resize_auto_cmd)
end

return M
