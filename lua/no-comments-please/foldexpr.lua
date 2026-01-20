local M = {}

M._comment_ranges = {} -- { [bufnr] = { {start, end}, ... } }
M._original_foldexpr = {} -- { [bufnr] = "original_expr" }

--- Check if a line is within any comment range using binary search
---@param bufnr number
---@param lnum number
---@return boolean, number? -- is_comment, fold_level
local function is_in_comment_range(bufnr, lnum)
    local ranges = M._comment_ranges[bufnr]
    if not ranges then
        return false, nil
    end

    -- Binary search for the range containing lnum
    -- Assumes ranges are sorted by start line (guaranteed by treesitter traversal order)
    local lo, hi = 1, #ranges
    while lo <= hi do
        local mid = math.floor((lo + hi) / 2)
        local range = ranges[mid]

        if lnum < range[1] then
            hi = mid - 1
        elseif lnum > range[2] then
            lo = mid + 1
        else
            -- Found: lnum is in this range
            if lnum == range[1] then
                return true, ">1" -- Start of fold
            elseif lnum == range[2] then
                return true, "<1" -- End of fold
            else
                return true, "1" -- Inside fold
            end
        end
    end

    return false, nil
end

--- Custom foldexpr that combines LSP folds with comment folds
---@return string
function M.hybrid_foldexpr()
    local bufnr = vim.api.nvim_get_current_buf()
    local lnum = vim.v.lnum

    -- Check if this line is in a comment range we're folding
    local in_comment, comment_level = is_in_comment_range(bufnr, lnum)
    if in_comment then
        return comment_level
    end

    -- Otherwise, delegate to original foldexpr (LSP)
    local original = M._original_foldexpr[bufnr]
    if original and original ~= "" then
        -- Directly call LSP foldexpr if that's what the original was
        if original:match("vim%.lsp%.foldexpr") or original:match("vim.lsp.foldexpr") then
            local result = vim.lsp.foldexpr()
            return tostring(result)
        end
        -- Fallback to eval for other foldexprs
        local ok, result = pcall(vim.fn.eval, original)
        if ok then
            return tostring(result)
        end
    end

    -- Fallback to no fold
    return "0"
end

--- Activate hybrid folding with comment ranges
---@param bufnr number
---@param ranges table[]
function M.activate(bufnr, ranges)
    -- Sort ranges by start line for binary search efficiency
    table.sort(ranges, function(a, b)
        return a[1] < b[1]
    end)

    -- Save comment ranges
    M._comment_ranges[bufnr] = ranges

    local current_foldexpr = vim.wo.foldexpr

    -- Save original foldexpr if not already saved
    -- Don't save if it's already our hybrid foldexpr
    if not M._original_foldexpr[bufnr] then
        if not current_foldexpr:match("comment%-fold") then
            M._original_foldexpr[bufnr] = current_foldexpr
        end
    end

    -- Set our hybrid foldexpr
    vim.wo.foldmethod = "expr"
    vim.wo.foldexpr = "v:lua.require'no-comments-please.foldexpr'.hybrid_foldexpr()"

    -- Recompute folds
    vim.cmd("normal! zx")

    -- Close only comment folds (not LSP folds like functions/structs)
    for _, range in ipairs(ranges) do
        -- Use Ex command with range to close fold without cursor movement
        pcall(vim.cmd, string.format("%d,%dfoldclose", range[1], range[2]))
    end
end

--- Deactivate hybrid folding, restore original
---@param bufnr number
function M.deactivate(bufnr)
    -- Clear comment ranges
    M._comment_ranges[bufnr] = nil

    -- Restore original foldexpr
    local original = M._original_foldexpr[bufnr]
    if original then
        vim.wo.foldexpr = original
        M._original_foldexpr[bufnr] = nil
    end

    -- Recompute folds
    vim.cmd("normal! zx")
end

--- Restore default foldexpr (configurable fallback)
---@param bufnr number
---@param foldexpr string
function M.restore_default_foldexpr(bufnr, foldexpr)
    -- Clear comment ranges and saved foldexpr
    M._comment_ranges[bufnr] = nil
    M._original_foldexpr[bufnr] = nil

    -- Set to the configured default foldexpr
    vim.wo.foldmethod = "expr"
    vim.wo.foldexpr = foldexpr

    -- No zx needed - Neovim recomputes folds automatically
end

return M
