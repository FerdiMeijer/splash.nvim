local M = {}

---Check if splash.nvim is properly configured and working
M.check = function()
	vim.health.start("splash.nvim")

	-- Check Neovim version
	local nvim_version = vim.version()
	if vim.fn.has("nvim-0.10") == 1 then
		vim.health.ok(string.format("Neovim version: %d.%d.%d", nvim_version.major, nvim_version.minor, nvim_version.patch))
	else
		vim.health.warn(
			string.format("Neovim version: %d.%d.%d", nvim_version.major, nvim_version.minor, nvim_version.patch),
			"splash.nvim works best with Neovim 0.10+"
		)
	end

	-- Check if splash module is loaded
	local ok, splash_module = pcall(require, "splash")
	if not ok then
		vim.health.error("Failed to load splash module", splash_module)
		return
	end
	vim.health.ok("splash module loaded successfully")

	-- Check if setup was called
	if not splash_module.options then
		vim.health.warn(
			"splash.setup() has not been called",
			"Call require('splash').setup({}) in your init.lua"
		)
		return
	end
	vim.health.ok("splash.setup() has been called")

	-- Check configuration
	local opts = splash_module.options

	-- Check file or lines configuration
	if opts.lines then
		if type(opts.lines) == "table" and #opts.lines > 0 then
			vim.health.ok(string.format("Using inline lines configuration (%d lines)", #opts.lines))
		else
			vim.health.error("opts.lines is set but empty or invalid", "Provide a table with at least one line")
		end
	elseif opts.file then
		local expanded_path = vim.fs.normalize(opts.file)
		local file_exists = vim.fn.filereadable(expanded_path) == 1

		if file_exists then
			vim.health.ok(string.format("ASCII art file exists: %s", expanded_path))

			-- Try to read the file
			local read_ok, lines = pcall(vim.fn.readfile, expanded_path)
			if read_ok and #lines > 0 then
				vim.health.ok(string.format("File is readable (%d lines)", #lines))

				-- Check for very large files (might cause performance issues)
				if #lines > 100 then
					vim.health.warn(
						string.format("ASCII art file is quite large (%d lines)", #lines),
						"Consider using smaller artwork for better startup performance"
					)
				end

				-- Check for very wide lines
				local max_width = 0
				for _, line in ipairs(lines) do
					max_width = math.max(max_width, #line)
				end
				if max_width > 200 then
					vim.health.warn(
						string.format("ASCII art contains very wide lines (%d characters)", max_width),
						"Consider using narrower artwork to fit better on screen"
					)
				end
			else
				vim.health.error("Failed to read ASCII art file", read_ok and "File is empty" or lines)
			end
		else
			vim.health.error(
				string.format("ASCII art file not found: %s", expanded_path),
				"Check the file path in your configuration"
			)
		end
	else
		vim.health.error("Neither 'lines' nor 'file' configured", "Provide either opts.lines or opts.file")
	end

	-- Check window configuration
	if opts.window then
		vim.health.ok("Window configuration provided")

		-- Validate border
		if opts.window.border then
			local valid_borders = { "none", "single", "double", "rounded", "solid", "shadow" }
			if type(opts.window.border) == "string" then
				local is_valid = vim.tbl_contains(valid_borders, opts.window.border)
				if is_valid then
					vim.health.ok(string.format("Border style: %s", opts.window.border))
				else
					vim.health.warn(
						string.format("Unknown border style: %s", opts.window.border),
						"Valid options: " .. table.concat(valid_borders, ", ")
					)
				end
			elseif type(opts.window.border) == "table" then
				vim.health.ok("Custom border table provided")
			end
		end

		-- Validate highlight
		if opts.window.highlight then
			if opts.window.highlight.blend then
				if opts.window.highlight.blend >= 0 and opts.window.highlight.blend <= 100 then
					vim.health.ok(string.format("Blend level: %d", opts.window.highlight.blend))
				else
					vim.health.warn(
						string.format("Invalid blend level: %d", opts.window.highlight.blend),
						"Blend should be between 0 and 100"
					)
				end
			end
		end
	else
		vim.health.ok("Using default window configuration")
	end

	-- Check enable_splash setting
	if type(opts.enable_splash) == "function" then
		vim.health.ok("Using custom enable_splash function")
		local test_result = opts.enable_splash()
		vim.health.info(string.format("Current enable_splash() result: %s", tostring(test_result)))
	elseif type(opts.enable_splash) == "boolean" then
		vim.health.ok(string.format("Splash screen enabled: %s", tostring(opts.enable_splash)))
	end

	vim.health.ok("Health check completed!")
end

return M
