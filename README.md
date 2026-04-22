# splash.nvim

`splash.nvim` is a configurable Neovim startup/splash screen plugin. It allows you to display custom ASCII art or text on Neovim startup, with flexible configuration for appearance and behavior.

![image](https://raw.githubusercontent.com/ferdimeijer/splash.nvim/main/demo1.png)
![image](https://raw.githubusercontent.com/ferdimeijer/splash.nvim/main/demo2.png)

## Features

- Show custom ASCII art or text on startup
- Configure splash window appearance (border, highlight, blend)
- Auto-close on user interaction (cursor movement, mode change, buffer switch)
- Auto-resize to stay centered when terminal is resized
- Built-in health check to verify configuration
- Type annotations for autocomplete support (LSP)

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
    enable_splash = true -- Boolean or function to determine if splash is shown. 
            -- Defaults to a function that returns true only when:
            -- * No command line arguments were used to start Neovim (e.g., opening a specific file)
            -- * Not in insert mode on startup
            -- * Current buffer is empty (no piped content)
})
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
