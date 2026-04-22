# splash.nvim

`splash.nvim` is a configurable Neovim startup/splash screen plugin. It allows you to display custom ASCII art or text on Neovim startup, with flexible configuration for appearance and behavior.

![image](https://raw.githubusercontent.com/ferdimeijer/splash.nvim/main/demo1.png)

## Features

- Show custom ASCII art or text on startup
- **Five unique animation types**: blend, breathe, typewriter, characters, and lines
- Configure splash window appearance (border, highlight, colors)
- Auto-close on user interaction (cursor movement, mode change)
- Auto-resize to stay centered when terminal is resized
- Built-in health check to verify configuration
- Type annotations for autocomplete support (LSP)
- Works on any terminal without special requirements

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
    "ferdimeijer/splash.nvim",
    opts = {
        -- optional configuration here
    },
}
```

Or with [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use {
    "ferdimeijer/splash.nvim",
    config = function()
        require("splash").setup({
            -- optional configuration here
        })
    end,
}
```

## Configuration

`splash.nvim` can be configured via the `setup` function or plugin manager `opts` table. Example options:

```lua
require("splash").setup({
    lines = { 
        "hello",
        "neovim!"
    }, -- Text to display. Defaults to empty (overrides file option if set)
    file = "~/.config/nvim/lua/hal9000.txt", -- Path to ASCII art file. Defaults to plugin's dragon.txt
    window = {
        -- See :h nvim_open_win for more border and highlight options
        highlight = { bg = "NONE", fg = "#800000", blend = 0 }, -- Splash window highlight options
        border = "single", -- Options: "none", "single", "rounded", "double", "solid", "shadow"
        -- Or use a custom border with highlight groups:
        -- border = {
        --     { "┌", "Normal" },
        --     { "─", "Normal" },
        --     { "┐", "Normal" },
        --     { "│", "Normal" },
        --     { "┘", "Normal" },
        --     { "─", "Normal" },
        --     { "└", "Normal" },
        --     { "│", "Normal" },
        -- },
    }, -- Defaults to { border = "none", highlight = { bg = "NONE", blend = 0 } }
    enable_logging = false, -- Enable splash logging to log buffer. Defaults to false
    remove_leading_whitespace = true, -- Remove leading whitespace that can be removed from each line of input. This will make sure the art is centered correctly. Defaults to true
    enable_splash = true, -- Boolean or function to determine if splash is shown. 
            -- Defaults to a function that returns true only when:
            -- * No command line arguments were used to start Neovim (e.g., opening a specific file)
            -- * Not in insert mode on startup
            -- * Current buffer is empty (no piped content)
    animation = {
        enabled = false, -- Enable fade-in animation. Defaults to false
        type = "blend", -- Animation type: "blend" (opacity fade), "characters" (random reveal), "lines" (line-by-line). Defaults to "blend"
        duration = 500, -- Animation duration in milliseconds. Defaults to 500
        fps = 30, -- Frames per second. Defaults to 30
        line_direction = "top_to_bottom", -- For "lines" type: "top_to_bottom" or "center_outward". Defaults to "top_to_bottom"
    },
})
```

## Animation

Splash.nvim supports five types of animations:

### **Blend Animation** (Default)
Smooth one-time color fade from dark to bright. Works on any terminal.

```lua
animation = {
    enabled = true,
    type = "blend",
    duration = 500,
    fps = 30,
}
```

**How it works:** The text starts very dark (almost invisible), then gradually brightens to the target foreground color.

### **Breathe Animation**
Continuous pulsing/breathing effect that loops until user interaction.

```lua
animation = {
    enabled = true,
    type = "breathe",
    duration = 3000,  -- Duration of one complete breath cycle
    fps = 30,
}
```

**How it works:** The text smoothly fades in (inhale), pauses at full brightness, fades out (exhale), pauses at darkness, then repeats. The animation automatically includes natural pauses with longer emphasis at full brightness (30% fade in, 25% pause bright, 30% fade out, 15% pause dark). When you press any key, the splash closes completely.

### **Typewriter Animation**
Types out the ASCII art character by character, line by line, like a typewriter.

```lua
animation = {
    enabled = true,
    type = "typewriter",
    duration = 2000,  -- Time to type entire art
    fps = 60,         -- Higher FPS for smoother typing
}
```

**How it works:** Characters appear one at a time from left to right, line by line, creating a typing effect. The speed automatically adjusts to complete within the specified duration.

### **Character Animation**
Characters appear randomly across the art, creating a "materializing" effect.

```lua
animation = {
    enabled = true,
    type = "characters",
    duration = 800,
    fps = 30,
}
```

### **Line Animation**
Art reveals line by line, either from top to bottom or center outward.

```lua
animation = {
    enabled = true,
    type = "lines",
    duration = 600,
    fps = 30,
    line_direction = "center_outward", -- or "top_to_bottom"
}
```

**Notes:**
- Pressing any key or moving the cursor will skip/stop the animation
- The "blend" and "breathe" animations work by transitioning text color
- The "breathe" animation loops continuously until user interaction, then closes the splash
- All animation types work on any terminal without special requirements

```

## Health Check

Verify your configuration is working correctly by running:

```vim
:checkhealth splash
```

The health check will validate:
- Neovim version compatibility
- Module loading status
- Configuration correctness
- ASCII art file existence and readability
- Window and highlight settings
- Potential performance issues (large files, wide lines)

## Requirements

- Neovim 0.10+ (recommended for best compatibility)
- Works with Neovim 0.9+ but some features may not be available

## License

MIT
See [LICENSE](LICENSE) for details.
