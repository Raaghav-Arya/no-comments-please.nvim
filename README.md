# no-comments-please.nvim

A Neovim plugin for folding comments using treesitter detection, while preserving LSP folding functionality.

## Features

- Fold all multi-line comments in the current buffer with a single command
- Preserves LSP folding for code structures
- Hybrid foldexpr approach combines comment folds with LSP folds
- Filters out inline comments (code + comment on same line)
- Configurable merging of consecutive comment blocks
- Automatic cleanup when saving sessions (works with persistence.nvim)
- Supports any language with treesitter parser

## Requirements

- Neovim >= 0.9.0
- Treesitter parser installed for your target language(s)

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
    "Raaghav-Arya/no-comments-please.nvim",
    opts = {},
    keys = {
        { "zh", "<cmd>CommentFoldToggle<cr>", desc = "Toggle comment folding" },
    },
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
    "Raaghav-Arya/no-comments-please.nvim",
    config = function()
        require("no-comments-please").setup()
    end
}
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'Raaghav-Arya/no-comments-please.nvim'
```

Then in your `init.lua`:
```lua
require("no-comments-please").setup()
```

## Usage

### Commands

- `:CommentFold` - Fold all multi-line comments in the current buffer
- `:CommentUnfold` - Unfold all comments and restore original foldexpr
- `:CommentFoldToggle` - Toggle comment folding

### Default Keybinding

If using the lazy.nvim config above, press `zh` to toggle comment folding.

## Configuration

The plugin can be configured via the `setup()` function:

```lua
require("no-comments-please").setup({
    -- Merge consecutive comment blocks into a single fold (default: true)
    merge_consecutive = true,

    -- Include blank lines between comments when merging (default: false)
    -- When true, comments separated only by blank lines will be merged
    include_blank_after = false,
})
```

### Configuration Examples

#### Default Configuration
```lua
{
    "Raaghav-Arya/no-comments-please.nvim",
    opts = {
        merge_consecutive = true,
        include_blank_after = false,
    },
}
```

#### Merge Comments Across Blank Lines
```lua
{
    "Raaghav-Arya/no-comments-please.nvim",
    opts = {
        merge_consecutive = true,
        include_blank_after = true,  -- Merge comments separated by blank lines
    },
}
```

#### No Merging
```lua
{
    "Raaghav-Arya/no-comments-please.nvim",
    opts = {
        merge_consecutive = false,  -- Each comment block gets its own fold
    },
}
```

## How It Works

1. **Treesitter Detection**: Uses treesitter to identify all comments in the buffer
2. **Filtering**: Removes single-line comments and inline comments
3. **Hybrid Foldexpr**: Creates a custom foldexpr that:
   - Routes comment lines to custom fold logic
   - Routes code lines to the original LSP foldexpr
4. **Session Cleanup**: Automatically restores original foldexpr when saving sessions (persistence.nvim)

## Compatibility

- Works with any LSP-based folding setup
- Compatible with [persistence.nvim](https://github.com/folke/persistence.nvim) for session management
- Supports all languages with treesitter parsers

## License

MIT License - see [LICENSE](LICENSE) file for details
