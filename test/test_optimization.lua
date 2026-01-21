-- Test script for optimization verification
vim.opt.runtimepath:append(".")

-- Load the plugin
local plugin = require("no-comments-please")
plugin.setup()

-- Open test file
vim.cmd("edit test/test_comments.lua")
vim.bo.filetype = "lua"

-- Test fold
print("Testing CommentFold...")
plugin.fold()

-- Verify we have folds
local bufnr = vim.api.nvim_get_current_buf()
local state = plugin._state[bufnr]

if state and state.folded then
    print("✓ Plugin folded successfully")
else
    print("✗ Plugin failed to fold")
    vim.cmd("cquit 1")
end

-- Test unfold
print("Testing CommentUnfold...")
plugin.unfold()

if state and not state.folded then
    print("✓ Plugin unfolded successfully")
else
    print("✗ Plugin failed to unfold")
    vim.cmd("cquit 1")
end

-- Test toggle
print("Testing CommentFoldToggle...")
plugin.toggle()
if state and state.folded then
    print("✓ Toggle to fold works")
else
    print("✗ Toggle to fold failed")
    vim.cmd("cquit 1")
end

plugin.toggle()
if state and not state.folded then
    print("✓ Toggle to unfold works")
else
    print("✗ Toggle to unfold failed")
    vim.cmd("cquit 1")
end

print("\nAll tests passed! Optimization 2 working correctly.")
vim.cmd("qall!")
