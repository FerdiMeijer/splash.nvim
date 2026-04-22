local log = require("splash.logging")

local M = {}

---Calculate number of animation steps based on duration and fps
---@param duration number Duration in milliseconds
---@param fps number Frames per second
---@return number steps Number of animation steps
---@return number interval Interval between frames in milliseconds
local function calculate_steps(duration, fps)
	local interval = math.floor(1000 / fps)
	local steps = math.floor(duration / interval)
	return steps, interval
end

---Safely close a timer without errors
---@param timer table Timer object
local function safe_close_timer(timer)
	if timer and not timer:is_closing() then
		pcall(function()
			safe_close_timer(timer)
		end)
	end
end

---Parse hex color to RGB components
---@param hex string Hex color like "#RRGGBB"
---@return number r Red component (0-255)
---@return number g Green component (0-255)
---@return number b Blue component (0-255)
local function hex_to_rgb(hex)
	-- Remove # if present
	hex = hex:gsub("#", "")

	-- Handle 3-digit hex
	if #hex == 3 then
		hex = hex:sub(1, 1):rep(2) .. hex:sub(2, 2):rep(2) .. hex:sub(3, 3):rep(2)
	end

	local r = tonumber(hex:sub(1, 2), 16) or 0
	local g = tonumber(hex:sub(3, 4), 16) or 0
	local b = tonumber(hex:sub(5, 6), 16) or 0

	return r, g, b
end

---Convert RGB to hex color
---@param r number Red component (0-255)
---@param g number Green component (0-255)
---@param b number Blue component (0-255)
---@return string hex Hex color like "#RRGGBB"
local function rgb_to_hex(r, g, b)
	return string.format("#%02X%02X%02X", math.floor(r + 0.5), math.floor(g + 0.5), math.floor(b + 0.5))
end

---Interpolate between two colors
---@param color1 string Start color hex
---@param color2 string End color hex
---@param progress number Progress from 0 to 1
---@return string color Interpolated color hex
local function interpolate_color(color1, color2, progress)
	local r1, g1, b1 = hex_to_rgb(color1)
	local r2, g2, b2 = hex_to_rgb(color2)

	local r = r1 + (r2 - r1) * progress
	local g = g1 + (g2 - g1) * progress
	local b = b1 + (b2 - b1) * progress

	return rgb_to_hex(r, g, b)
end

---Typewriter animation - types out characters one at a time, line by line
---@param buffer number Buffer handle
---@param lines table Original lines
---@param options table Animation options
---@param on_complete? function Callback when animation completes
M.fade_in_typewriter = function(buffer, lines, options, on_complete)
	log.debug("Starting typewriter animation")

	if not vim.api.nvim_buf_is_valid(buffer) then
		return nil
	end

	local duration = options.duration or 2000
	local fps = options.fps or 60 -- Higher FPS for smoother typing

	-- Count total characters (excluding spaces at line endings)
	local total_chars = 0
	for _, line in ipairs(lines) do
		total_chars = total_chars + #line
	end

	-- Calculate characters per frame for desired duration
	local interval = math.floor(1000 / fps)
	local total_frames = math.floor(duration / interval)
	local chars_per_frame = math.max(1, math.ceil(total_chars / total_frames))

	log.debug(
		string.format("Typewriter: %d chars, %d frames, %d chars/frame", total_chars, total_frames, chars_per_frame)
	)

	-- Start with empty lines
	local current_lines = {}
	for i = 1, #lines do
		current_lines[i] = ""
	end
	vim.api.nvim_buf_set_lines(buffer, 0, -1, false, current_lines)

	local current_line = 1
	local current_col = 1
	local chars_typed = 0

	local timer = vim.loop.new_timer()
	timer:start(
		interval,
		interval,
		vim.schedule_wrap(function()
			if not vim.api.nvim_buf_is_valid(buffer) then
				safe_close_timer(timer)
				return
			end

			-- Type multiple characters per frame for speed control
			for _ = 1, chars_per_frame do
				if current_line > #lines then
					break
				end

				local target_line = lines[current_line]

				-- If we've finished this line, move to next
				if current_col > #target_line then
					current_line = current_line + 1
					current_col = 1
					if current_line > #lines then
						break
					end
					target_line = lines[current_line]
				end

				-- Add one character to current line
				if current_col <= #target_line then
					local char = target_line:sub(current_col, current_col)
					current_lines[current_line] = current_lines[current_line] .. char
					current_col = current_col + 1
					chars_typed = chars_typed + 1
				end
			end

			-- Update the buffer with current progress
			vim.api.nvim_buf_set_lines(buffer, 0, -1, false, current_lines)

			-- Check if complete
			if current_line > #lines or chars_typed >= total_chars then
				-- Ensure final state is exact
				vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
				safe_close_timer(timer)
				log.debug("Typewriter animation completed")
				if on_complete then
					on_complete()
				end
			end
		end)
	)

	return timer
end

---Breathe animation - continuous fade in/out with pauses
---@param buffer number Buffer handle
---@param window number Window handle
---@param namespace number Namespace ID
---@param lines table Original lines
---@param options table Animation options
---@param original_highlight table Original highlight settings
---@param on_complete? function Callback when animation completes
M.fade_in_breathe = function(buffer, window, namespace, lines, options, original_highlight, on_complete)
	log.debug("Starting breathe animation")
	log.debug("Original highlight: " .. vim.inspect(original_highlight))

	if not vim.api.nvim_buf_is_valid(buffer) then
		return nil
	end

	local total_duration = options.duration or 3000
	local fps = options.fps or 30

	-- Calculate phase durations with longer pause at bright (30-25-30-15)
	-- This makes the final bright state more prominent
	local fade_in_duration = total_duration * 0.30
	local pause_bright_duration = total_duration * 0.25 -- Increased from 15% to 25%
	local fade_out_duration = total_duration * 0.30
	local pause_dark_duration = total_duration * 0.15

	-- Get target foreground color
	local fg_color = original_highlight.fg

	if not fg_color or fg_color == "none" or fg_color == "NONE" or fg_color == "" then
		fg_color = "#FFFFFF"
	end

	-- Ensure fg color starts with #
	if not fg_color:match("^#") then
		fg_color = "#" .. fg_color
	end

	-- Darken to about 5% of target brightness
	local fr, fg, fb = hex_to_rgb(fg_color)
	local start_color = rgb_to_hex(fr * 0.05, fg * 0.05, fb * 0.05)

	log.debug("Breathing between: " .. start_color .. " and: " .. fg_color)

	-- Phase tracking
	local phase = "fade_in" -- "fade_in", "pause_bright", "fade_out", "pause_dark"
	local phase_start_time = vim.loop.now()
	local hl_name_prefix = "SplashBreathe"

	-- Set initial dark color
	local initial_hl = hl_name_prefix .. "0"
	local bg = original_highlight.bg or "NONE"
	vim.api.nvim_set_hl(0, initial_hl, { fg = start_color, bg = bg })
	for i = 0, #lines - 1 do
		vim.api.nvim_buf_add_highlight(buffer, namespace, initial_hl, i, 0, -1)
	end

	local frame_interval = math.floor(1000 / fps)
	local frame_count = 0
	local timer_closing = false

	local timer = vim.loop.new_timer()
	timer:start(frame_interval, frame_interval, function()
		vim.schedule(function()
			if timer_closing then
				return
			end
			
			if not vim.api.nvim_buf_is_valid(buffer) then
				if not timer_closing then
					timer_closing = true
					safe_close_timer(timer)
				end
				return
			end

			frame_count = frame_count + 1
			local elapsed = vim.loop.now() - phase_start_time
			local current_color = start_color

			if phase == "fade_in" then
				local phase_progress = math.min(elapsed / fade_in_duration, 1.0)
				current_color = interpolate_color(start_color, fg_color, phase_progress)

				if elapsed >= fade_in_duration then
					phase = "pause_bright"
					phase_start_time = vim.loop.now()
					log.debug("Breathe: inhale complete, pausing at bright")
				end
			elseif phase == "pause_bright" then
				current_color = fg_color -- Hold at bright

				if elapsed >= pause_bright_duration then
					phase = "fade_out"
					phase_start_time = vim.loop.now()
					log.debug("Breathe: starting exhale")
				end
			elseif phase == "fade_out" then
				local phase_progress = math.min(elapsed / fade_out_duration, 1.0)
				current_color = interpolate_color(fg_color, start_color, phase_progress)

				if elapsed >= fade_out_duration then
					phase = "pause_dark"
					phase_start_time = vim.loop.now()
					log.debug("Breathe: exhale complete, pausing at dark")
				end
			elseif phase == "pause_dark" then
				current_color = start_color -- Hold at dark

				if elapsed >= pause_dark_duration then
					phase = "fade_in"
					phase_start_time = vim.loop.now()
					log.debug("Breathe: cycle complete, starting new inhale")
				end
			end

			-- Apply current color
			local hl_name = hl_name_prefix .. frame_count
			vim.api.nvim_set_hl(0, hl_name, { fg = current_color, bg = bg })

			vim.api.nvim_buf_clear_namespace(buffer, namespace, 0, -1)
			for i = 0, #lines - 1 do
				vim.api.nvim_buf_add_highlight(buffer, namespace, hl_name, i, 0, -1)
			end
		end)
	end)

	return timer
end

---Fade in animation using color interpolation with extmarks
---@param buffer number Buffer handle
---@param window number Window handle
---@param namespace number Namespace ID
---@param lines table Original lines
---@param options table Animation options
---@param original_highlight table Original highlight settings
---@param on_complete? function Callback when animation completes
M.fade_in_blend = function(buffer, window, namespace, lines, options, original_highlight, on_complete)
	log.debug("Starting color-based fade-in animation")
	log.debug("Original highlight: " .. vim.inspect(original_highlight))

	if not vim.api.nvim_buf_is_valid(buffer) then
		return nil
	end

	local duration = options.duration or 500
	local fps = options.fps or 30
	local steps, interval = calculate_steps(duration, fps)

	-- Get target foreground color
	local fg_color = original_highlight.fg

	if not fg_color or fg_color == "none" or fg_color == "NONE" or fg_color == "" then
		fg_color = "#FFFFFF"
	end

	-- Ensure fg color starts with #
	if not fg_color:match("^#") then
		fg_color = "#" .. fg_color
	end

	-- For fade animation, start from a darkened version of the target color
	-- This creates a better visual effect than fading from the background color
	local fr, fg, fb = hex_to_rgb(fg_color)
	-- Darken to about 5% of target brightness for smooth fade
	local start_color = rgb_to_hex(fr * 0.05, fg * 0.05, fb * 0.05)

	log.debug("Fading from: " .. start_color .. " to: " .. fg_color)

	-- Create highlight groups for each frame
	local hl_name_prefix = "SplashFade"
	local current_step = 0

	-- Set initial dark color BEFORE starting animation to prevent flash
	local initial_hl = hl_name_prefix .. "0"
	local bg = original_highlight.bg or "NONE"
	vim.api.nvim_set_hl(0, initial_hl, { fg = start_color, bg = bg })
	for i = 0, #lines - 1 do
		vim.api.nvim_buf_add_highlight(buffer, namespace, initial_hl, i, 0, -1)
	end

	local timer = vim.loop.new_timer()
	timer:start(interval, interval, function()
		vim.schedule(function()
			if not vim.api.nvim_buf_is_valid(buffer) then
				safe_close_timer(timer)
				return
			end

			current_step = current_step + 1
			local progress = current_step / steps

			-- Interpolate color
			local current_color = interpolate_color(start_color, fg_color, progress)

			-- Log every 10th frame
			if current_step % 10 == 0 or current_step == 1 or current_step >= steps then
				log.debug(
					string.format(
						"Frame %d/%d (%.1f%%): color = %s",
						current_step,
						steps,
						progress * 100,
						current_color
					)
				)
			end

			-- Create a unique highlight group for this frame's color
			local hl_name = hl_name_prefix .. current_step
			local bg = original_highlight.bg or "NONE"
			vim.api.nvim_set_hl(0, hl_name, { fg = current_color, bg = bg })

			-- Apply highlight to entire buffer
			vim.api.nvim_buf_clear_namespace(buffer, namespace, 0, -1)
			for i = 0, #lines - 1 do
				vim.api.nvim_buf_add_highlight(buffer, namespace, hl_name, i, 0, -1)
			end

			if current_step >= steps then
				-- Final frame - use the original highlight namespace
				log.debug("Animation complete - setting final color: " .. fg_color)
				vim.api.nvim_buf_clear_namespace(buffer, namespace, 0, -1)

				-- Set final color in the namespace
				vim.api.nvim_set_hl(namespace, "Normal", original_highlight)

				safe_close_timer(timer)
				log.debug("Color-based fade-in animation completed")
				if on_complete then
					on_complete()
				end
			end
		end)
	end)

	return timer
end

---Fade in animation revealing characters gradually
---@param buffer number Buffer handle
---@param lines table Original lines
---@param options table Animation options
---@param on_complete? function Callback when animation completes
M.fade_in_characters = function(buffer, lines, options, on_complete)
	log.debug("Starting character-based fade-in animation")

	if not vim.api.nvim_buf_is_valid(buffer) then
		return nil
	end

	local duration = options.duration or 500
	local fps = options.fps or 30
	local steps, interval = calculate_steps(duration, fps)

	-- Create a character map for gradual reveal
	local char_positions = {}
	for i, line in ipairs(lines) do
		for j = 1, #line do
			if line:sub(j, j) ~= " " then
				table.insert(char_positions, { line = i, col = j, char = line:sub(j, j) })
			end
		end
	end

	-- Shuffle positions for random reveal
	for i = #char_positions, 2, -1 do
		local j = math.random(i)
		char_positions[i], char_positions[j] = char_positions[j], char_positions[i]
	end

	-- Start with blank lines
	local current_lines = {}
	for i, line in ipairs(lines) do
		current_lines[i] = string.rep(" ", #line)
	end
	vim.api.nvim_buf_set_lines(buffer, 0, -1, false, current_lines)

	local chars_per_step = math.max(1, math.ceil(#char_positions / steps))
	local current_step = 0
	local char_index = 0

	local timer = vim.loop.new_timer()
	timer:start(
		interval,
		interval,
		vim.schedule_wrap(function()
			if not vim.api.nvim_buf_is_valid(buffer) then
				safe_close_timer(timer)
				return
			end

			current_step = current_step + 1

			-- Reveal characters for this step
			for _ = 1, chars_per_step do
				char_index = char_index + 1
				if char_index > #char_positions then
					break
				end

				local pos = char_positions[char_index]
				local line = current_lines[pos.line]
				current_lines[pos.line] = line:sub(1, pos.col - 1) .. pos.char .. line:sub(pos.col + 1)
			end

			vim.api.nvim_buf_set_lines(buffer, 0, -1, false, current_lines)

			if current_step >= steps or char_index >= #char_positions then
				-- Ensure final state is exact
				vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
				safe_close_timer(timer)
				log.debug("Character fade-in animation completed")
				if on_complete then
					on_complete()
				end
			end
		end)
	)

	return timer
end

---Fade in animation revealing lines from top to bottom or center outward
---@param buffer number Buffer handle
---@param lines table Original lines
---@param options table Animation options
---@param on_complete? function Callback when animation completes
M.fade_in_lines = function(buffer, lines, options, on_complete)
	log.debug("Starting line-based fade-in animation")

	if not vim.api.nvim_buf_is_valid(buffer) then
		return nil
	end

	local duration = options.duration or 500
	local fps = options.fps or 30
	local steps, interval = calculate_steps(duration, fps)
	local direction = options.line_direction or "top_to_bottom" -- "top_to_bottom" or "center_outward"

	-- Start with blank lines
	local blank_lines = {}
	for i = 1, #lines do
		blank_lines[i] = string.rep(" ", #lines[i])
	end
	vim.api.nvim_buf_set_lines(buffer, 0, -1, false, blank_lines)

	local line_order = {}
	if direction == "center_outward" then
		local center = math.ceil(#lines / 2)
		for i = 0, math.max(center - 1, #lines - center) do
			if center - i >= 1 then
				table.insert(line_order, center - i)
			end
			if center + i <= #lines and i > 0 then
				table.insert(line_order, center + i)
			end
		end
	else -- top_to_bottom
		for i = 1, #lines do
			line_order[i] = i
		end
	end

	local lines_per_step = math.max(1, math.ceil(#lines / steps))
	local current_step = 0
	local line_index = 0

	local timer = vim.loop.new_timer()
	timer:start(
		interval,
		interval,
		vim.schedule_wrap(function()
			if not vim.api.nvim_buf_is_valid(buffer) then
				safe_close_timer(timer)
				return
			end

			current_step = current_step + 1

			-- Reveal lines for this step
			for _ = 1, lines_per_step do
				line_index = line_index + 1
				if line_index > #line_order then
					break
				end

				local line_num = line_order[line_index]
				vim.api.nvim_buf_set_lines(buffer, line_num - 1, line_num, false, { lines[line_num] })
			end

			if current_step >= steps or line_index >= #line_order then
				-- Ensure final state is exact
				vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
				safe_close_timer(timer)
				log.debug("Line fade-in animation completed")
				if on_complete then
					on_complete()
				end
			end
		end)
	)

	return timer
end

---Start animation based on configuration
---@param buffer number Buffer handle
---@param window number Window handle
---@param namespace number Namespace ID
---@param lines table Original lines
---@param options table Animation configuration
---@param original_highlight table Original highlight settings
---@return table|nil timer Timer object or nil if animation disabled
M.start = function(buffer, window, namespace, lines, options, original_highlight)
	if not options or not options.enabled then
		log.debug("Animation disabled")
		return nil
	end

	local animation_type = options.type or "blend"

	if animation_type == "blend" then
		return M.fade_in_blend(buffer, window, namespace, lines, options, original_highlight)
	elseif animation_type == "breathe" then
		return M.fade_in_breathe(buffer, window, namespace, lines, options, original_highlight)
	elseif animation_type == "typewriter" then
		return M.fade_in_typewriter(buffer, lines, options)
	elseif animation_type == "characters" then
		return M.fade_in_characters(buffer, lines, options)
	elseif animation_type == "lines" then
		return M.fade_in_lines(buffer, lines, options)
	else
		log.err("Unknown animation type: " .. animation_type)
		return nil
	end
end

---Stop animation immediately
---@param timer table|nil Timer object
M.stop = function(timer)
	safe_close_timer(timer)
	log.debug("Animation stopped")
end

return M
