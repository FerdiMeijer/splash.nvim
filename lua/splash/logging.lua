local M = {}

M.enabled = false

local log = function(msg, level)
	if not M.enabled then
		return
	end

	if M.buffer == nil then
		M.buffer = vim.api.nvim_create_buf(true, true)
		vim.api.nvim_buf_set_name(M.buffer, "splash_log")
	end

	-- transform the integer log level to its string representation.
	local level_str = "INFO"
	for l, i in pairs(vim.log.levels) do
		if level == i then
			level_str = l
		end
	end

	-- ensure `msg` is always a table to make processing simpler
	if type(msg) == "string" then
		msg = { msg }
	end

	-- Split `msg` on newlines, since nvim_buf_set_lines() does not like them
	msg = vim.tbl_map(function(line)
		return vim.split(line, "\n")
	end, msg)
	msg = vim.iter(msg):flatten(1):totable()

	-- for each line add the log level
	local time = os.date("*t")
	local complete_msg = vim.tbl_map(function(line)
		return time.hour .. ":" .. time.min .. ":" .. time.sec .. "[" .. level_str .. "] " .. line
	end, msg)

	-- actually add the lines to the buffer
	vim.api.nvim_buf_set_lines(M.buffer, -1, -1, true, complete_msg)
end

local logging_func_for = function(level)
	return function(msg)
		log(msg, level)
	end
end

M.trace = logging_func_for(vim.log.levels.TRACE)
M.debug = logging_func_for(vim.log.levels.DEBUG)
M.info = logging_func_for(vim.log.levels.INFO)
M.warn = logging_func_for(vim.log.levels.WARN)
M.error = logging_func_for(vim.log.levels.ERROR)

return M
