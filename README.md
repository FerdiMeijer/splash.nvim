# splash.nvim

`splash.nvim` is a configurable Neovim startup/splash screen plugin. It allows you to display custom ASCII art or text on Neovim startup, with flexible configuration for appearance and behavior.

## Features

- Show custom ASCII art or text on startup
- Configure splash window appearance (border, highlight, blend)

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
    "ferdimeijer/splash.nvim",
    opts = {
        -- optionally: your configuration options here
    },
}
```

Or with [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use {
    "ferdimeijer/splash.nvim",
    config = function()
        require("splash").setup({
            -- optionally: your configuration options here
        })
    end,
}
```

## Configuration

`splash.nvim` can be configured via the `setup` function or plugin manager `opts` table. Example options:

```lua
require("splash").setup({
    input = { 
        "hello",
        "neovim!"
    },-- text to display. Defaults to empty (overrides file option if set)
    file = "~/.config/nvim/lua/dragon.txt", -- Path to ASCII art file. Defaults to `<plugin_dir>/../art/dragon.txt`
    window = {
        --see :h nvim_open_win config parameters for more border and highlight options
        highlight = { bg = "NONE", fg = "#800000", blend = 0 }, -- Window highlight options
        border = { "single", highlight = { bg = "NONE", blend = 0 } },
 		--border = { "╔", "═", "╗", "║", "╝", "═", "╚", "║" }, -- custom border
    }, -- defaults to `{ border = "none", highlight = { bg = "NONE", blend = 0 } }`
    enable_logging = false, -- Enable splash logging to log buffer. Defaults to false
    remove_leading_whitespace = true, -- remove leading whitespace that can be removed from each line of input this will make sure the art is centered correctly. Defaults to true
    enable_splash = true -- function to determine if splash is shown, 
            -- defaults to a function that does not show splash screen if:
            -- * the user is in insert mode
            -- * if there are no buffers open already,
            -- * when command line arguments were used to start neovim, i.e. to open a specific file.
})
```

## License

MIT
```

