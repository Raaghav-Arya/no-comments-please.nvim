-- Test file for no-comments-please.nvim
-- This file contains various Lua comment patterns to test folding behavior

-- Single-line comment (should NOT fold)

local function example1()
    return "code"
end

--[[
Multi-line block comment that spans
multiple lines. This should be folded
when the plugin is active.
]]

local function example2()
    local x = 10 -- inline comment (should NOT fold)
    return x * 2
end

-- Another single-line comment (should NOT fold)

--[[
This is another multi-line comment block.
It contains several lines of text.
This should also be folded.
]]

local M = {}

--[[
Documentation comment for the module.
This is a typical pattern in Lua modules.
Should be foldable.
]]

function M.method1()
    return "method1"
end

-- Single comment between methods

function M.method2()
    return "method2"
end

--[[
First consecutive block comment.
This is part of a series of comment blocks.
]]

--[[
Second consecutive block comment.
When merge_consecutive is enabled,
this should be merged with the previous one.
]]

function M.with_nested_structure()
    if true then
        --[[
        Nested multi-line comment inside a function.
        Should be foldable independently.
        ]]
        return {
            key = "value" -- inline comment (should NOT fold)
        }
    end
end

--[=[
Long-form multi-line comment syntax.
This uses the long-form delimiter with equal signs.
Should also be foldable.
]=]

function M.final_method()
    -- Single line comment in function body
    local result = 42
    return result
end

--[[
Final multi-line comment block.
Testing if comment folding works at the end of file.
]]

return M
