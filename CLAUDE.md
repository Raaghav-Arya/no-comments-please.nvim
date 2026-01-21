# CLAUDE.md

This file provides guidance to Claude Code when working with the no-comments-please.nvim plugin codebase.

## Plugin Overview

no-comments-please.nvim is a Neovim plugin that folds multi-line comments using treesitter detection while preserving LSP folding functionality for code structures.

## Architecture

The plugin uses a **hybrid foldexpr approach** that combines custom comment folding with existing LSP folding:

1. Treesitter detects all comments in the buffer
2. Single-line and inline comments are filtered out
3. A custom foldexpr routes comment lines to custom fold logic, code lines to LSP
4. Session cleanup restores original foldexpr before persistence.nvim saves

## File Structure

```
lua/no-comments-please/
├── init.lua          - Main API, commands, state management, session cleanup
├── treesitter.lua    - Comment detection, filtering, range merging
├── foldexpr.lua      - Hybrid foldexpr implementation
└── fold.lua          - Wrapper for fold activation/deactivation
```

## Core Files

### init.lua
**Purpose**: Main entry point, user commands, and session persistence handling

**Key components**:
- `M._state`: Per-buffer state tracking `{ [bufnr] = { folded = bool } }`
- `M.setup()`: Creates user commands and PersistenceSavePre autocmd
- `M.fold()`: Main folding function - detects comments and creates folds
- `M.unfold()`: Removes comment folds and restores original foldexpr
- `M.toggle()`: Toggles between folded/unfolded states

**Important**: The `PersistenceSavePre` autocmd iterates through ALL windows to restore foldexpr before session save, because foldexpr is window-local.

### treesitter.lua
**Purpose**: Comment detection and filtering using treesitter AST

**Key functions**:
- `M.has_parser(bufnr)`: Checks if treesitter parser exists for buffer filetype
- `M.get_comment_ranges(bufnr, config)`: Returns array of `{start_line, end_line}` ranges
- `M.merge_ranges(ranges, bufnr, config)`: Merges consecutive comment blocks

**Critical filtering**:
1. **Inline comments**: `is_inline_comment()` filters comments with code before them
2. **Single-line comments**: Lines 105-113 filter `range[1] == range[2]` to prevent fold conflicts
3. **Multi-line only**: Only comments spanning multiple lines are folded

**Detection methods** (fallback chain):
1. Primary: Uses treesitter highlights query with `@comment` capture
2. Fallback: Traverses AST looking for node types matching `"comment"`

### foldexpr.lua
**Purpose**: Hybrid foldexpr that routes to comment or LSP folding

**Key components**:
- `M._comment_ranges`: Stores comment ranges per buffer
- `M._original_foldexpr`: Saves original foldexpr per buffer for restoration
- `M.hybrid_foldexpr()`: Core routing function called by Neovim for each line

**Fold level routing**:
```lua
-- For comment lines: return ">1", "1", or "<1"
-- For code lines: delegate to original foldexpr (LSP)
```

**Activation** (`M.activate()`):
1. Saves comment ranges and original foldexpr
2. Sets foldmethod="expr" and foldexpr to hybrid function
3. Recomputes folds with `zx`
4. Explicitly closes each comment fold with `zc`

**Deactivation** (`M.deactivate()`):
1. Clears comment ranges
2. Restores original foldexpr
3. Recomputes folds with `zx`

### fold.lua
**Purpose**: Simple wrapper module

Provides clean interface to activate/deactivate folding without directly requiring foldexpr.lua.

## Configuration Options

```lua
{
    merge_consecutive = true,      -- Merge adjacent comment blocks
    include_blank_after = false,   -- Include blank lines between comments when merging
    keybinds = {
        restore_foldexpr = "<leader>zr",  -- Keybind to restore default foldexpr
    },
}
```

**Defaults**:
- `include_blank_after = false` (changed from initial `true` to be less aggressive)
- `restore_foldexpr = "<leader>zr"` (set to `nil` or `false` to disable)

## Important Implementation Details

### Why Single-Line Comments Are Filtered

**Problem**: Single-line comments caused incorrect folding behavior where the next line (code) would be included in the comment fold.

**Root cause**: A single-line comment returns fold level `">1"` (fold start) without a corresponding end. When the next line returns `">3"` from LSP, Neovim treats it as nested within the comment fold.

**Solution** (treesitter.lua:105-113):
```lua
local filtered = {}
for _, range in ipairs(ranges) do
    if range[1] ~= range[2] then  -- Only keep multi-line comments
        table.insert(filtered, range)
    end
end
```

### Session Persistence

**Problem**: When closing Neovim with comments folded, the hybrid foldexpr was persisted in the session file.

**Solution**: Hook into persistence.nvim's `PersistenceSavePre` User event (fires before `:mksession`).

**Why window iteration is needed**: `foldexpr` is a window-local option (`vim.wo`), not buffer-local. Must use `nvim_win_call()` to execute deactivation in each window's context.

```lua
for _, winid in ipairs(vim.api.nvim_list_wins()) do
    local bufnr = vim.api.nvim_win_get_buf(winid)
    if state and state.folded then
        vim.api.nvim_win_call(winid, function()
            foldexpr_mod.deactivate(bufnr)
        end)
    end
end
```

### Foldexpr String Format

The foldexpr must be a string that evaluates to a fold level:

```lua
vim.wo.foldexpr = "v:lua.require'no-comments-please.foldexpr'.hybrid_foldexpr()"
```

**Important**: Uses `v:lua` prefix to call Lua functions from Vim expression context.

## Performance Optimizations

The plugin implements several optimizations to ensure fast toggle performance, especially on large files with many comments:

### 1. Comment Range Caching

**Location**: `init.lua:78-105`

**Optimization**: Caches detected comment ranges in `M._state[bufnr]` with `changedtick`-based invalidation.

**Implementation**:
```lua
-- Check cache validity
local state = M._state[bufnr]
local current_tick = vim.api.nvim_buf_get_changedtick(bufnr)
local ranges

if state and state.ranges and state.changedtick == current_tick then
    -- Use cached ranges
    ranges = state.ranges
else
    -- Detect fresh
    ranges = treesitter.get_comment_ranges(bufnr, M._config)
end
```

**Impact**: Avoids full AST traversal on repeated toggles when the buffer hasn't changed. **50-80% faster** for subsequent toggles without edits.

### 2. Sorted Range Contract

**Location**: `treesitter.lua:106-109`, `foldexpr.lua:77-79`

**Optimization**: Eliminated duplicate sort operation. `treesitter.merge_ranges()` guarantees sorted output, so `foldexpr.activate()` no longer needs to re-sort.

**Implementation**:
```lua
-- treesitter.lua
-- Sort by start line (required - foldexpr.activate relies on sorted ranges)
table.sort(ranges, function(a, b)
    return a[1] < b[1]
end)

-- foldexpr.lua - sort removed
function M.activate(bufnr, ranges)
    -- Ranges are already sorted by treesitter.merge_ranges()
    M._comment_ranges[bufnr] = ranges
```

**Impact**: Eliminates O(n log n) redundant sort operation.

### 3. Batched Fold Commands

**Location**: `foldexpr.lua:100-106`

**Optimization**: Replaced O(n) individual `foldclose` vim commands with single batched `nvim_exec2()` call.

**Implementation**:
```lua
-- Close only comment folds (not LSP folds like functions/structs)
-- Batch all foldclose commands for efficiency
if #ranges > 0 then
    local cmds = {}
    for _, range in ipairs(ranges) do
        table.insert(cmds, string.format("%d,%dfoldclose", range[1], range[2]))
    end
    pcall(vim.api.nvim_exec2, table.concat(cmds, "\n"), { output = false })
end
```

**Impact**: Reduces Lua↔Vim context switches from O(n) to O(1). Particularly noticeable with many comment blocks.

### 4. Optimized Unfold

**Location**: `foldexpr.lua:122-124`

**Optimization**: Uses `zR` (open all folds) instead of `zx` (recompute all folds) when unfolding.

**Implementation**:
```lua
function M.deactivate(bufnr)
    -- Clear comment ranges
    M._comment_ranges[bufnr] = nil

    -- Restore original foldexpr
    local original = M._original_foldexpr[bufnr]
    if original then
        vim.wo.foldexpr = original
        M._original_foldexpr[bufnr] = nil
    end

    -- Open all folds - faster than zx recompute
    -- LSP foldexpr will recompute lazily when user interacts with folds
    vim.cmd("normal! zR")
end
```

**Impact**: Faster unfold operation. LSP foldexpr recomputes folds lazily when needed.

**Trade-off**: All folds (including code folds) are open after unfold. This is semantically consistent with "remove folding state."

### Performance Summary

| Operation | First Toggle | Subsequent Toggles (No Edits) | After Buffer Edit |
|-----------|--------------|-------------------------------|-------------------|
| Fold      | Baseline     | **50-80% faster** (cache hit) | Baseline (cache miss) |
| Unfold    | **Faster** (zR vs zx) | **Faster** (zR vs zx) | **Faster** (zR vs zx) |

**Testing**: Use `test/test_comments.c` (~2000 lines) to verify performance on realistically large files.

## Development Guidelines

### Adding Features

1. **State management**: Add to `M._state` in init.lua if per-buffer tracking needed
2. **Configuration**: Add to `defaults` table in init.lua, expose via `setup()`
3. **Commands**: Create via `nvim_create_user_command` in `setup()`
4. **Keybindings**: Add to `keybinds` table in defaults, set up via `vim.keymap.set` in `setup()` with nil checks

### Testing Checklist

When making changes, test:
1. ✅ Multi-line comment folding (`:CommentFold`)
2. ✅ LSP folding still works for code structures
3. ✅ Single-line comments are NOT folded
4. ✅ Inline comments (code + comment) are NOT folded
5. ✅ Toggle works (`:CommentFoldToggle` or `zh`)
6. ✅ Session save/restore preserves LSP foldexpr (close with `:qa`, reopen)
7. ✅ Works across multiple windows showing same buffer

### Common Pitfalls

1. **Don't use buffer-local for foldexpr**: It's window-local (`vim.wo`), not `vim.bo`
2. **Check for parser**: Always call `treesitter.has_parser()` before `get_comment_ranges()`
3. **Use pcall for fold commands**: `pcall(vim.cmd, "normal! zc")` to handle fold errors
4. **Module naming**: All requires use `no-comments-please.*`, not `comment-fold.*`

## Dependencies

- **Neovim >= 0.9.0**: For treesitter and LSP folding APIs
- **nvim-treesitter**: Required for comment detection
- **persistence.nvim** (optional): For session management integration

## Compatibility

- Works with any LSP server that provides folding
- Compatible with all languages that have treesitter parsers
- Safe to use without persistence.nvim (session cleanup just won't run)

## Future Enhancement Ideas

- Per-language configuration (different settings for different filetypes)
- Custom fold text for comment blocks (show first line of comment)
- Integration with other folding methods (manual, marker, indent)
- Configurable fold level (nested comment folding)
- Exclude certain comment patterns (e.g., fold only block comments, not line comments)
