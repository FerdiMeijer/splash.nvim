local M = {}

M.auto_cmds = {}

M.setup_close = function(callback)
	vim.api.nvim_create_autocmd("VimEnter", {
		callback = function()
			-- slight delay to allow other plugins to settle
			vim.defer_fn(function()
				for _, event in ipairs({ "ModeChanged", "CursorMoved" }) do --, "TextChanged", "WinScrolled"
					local auto_cmd = vim.api.nvim_create_autocmd(event, {
						callback = function()
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
			end, 100)
		end,
	})
end

M.setup_resize = function(callback)
	local resize_auto_cmd = vim.api.nvim_create_autocmd("VimResized", {
		callback = function()
			callback()

			-- auto cleanup auto_cmds
			for _, id in ipairs(M.auto_cmds) do
				vim.api.nvim_del_autocmd(id)
			end
			M.auto_cmds = {}
		end,
	})

	table.insert(M.auto_cmds, resize_auto_cmd)
end

return M
