-- Test script for cache optimization verification
vim.opt.runtimepath:append(".")

-- Load the plugin
local plugin = require("no-comments-please")
plugin.setup()

-- Open test file
vim.cmd("edit test/test_comments.lua")
vim.bo.filetype = "lua"

local bufnr = vim.api.nvim_get_current_buf()

-- Test 1: First fold should detect ranges
print("Test 1: First fold (should detect ranges)...")
plugin.fold()
local state1 = plugin._state[bufnr]
assert(state1.folded, "Should be folded")
assert(state1.ranges, "Should have ranges")
assert(state1.changedtick, "Should have changedtick")
local initial_tick = state1.changedtick
print("✓ First fold detected " .. #state1.ranges .. " comment blocks")

-- Test 2: Unfold should preserve cache
print("\nTest 2: Unfold (should preserve cache)...")
plugin.unfold()
local state2 = plugin._state[bufnr]
assert(not state2.folded, "Should be unfolded")
assert(state2.ranges, "Should still have cached ranges")
assert(state2.changedtick == initial_tick, "Should preserve changedtick")
print("✓ Unfold preserved cache")

-- Test 3: Second fold should use cache (no buffer changes)
print("\nTest 3: Second fold (should use cache)...")
local tick_before_fold = vim.api.nvim_buf_get_changedtick(bufnr)
plugin.fold()
local state3 = plugin._state[bufnr]
assert(state3.folded, "Should be folded")
assert(state3.changedtick == tick_before_fold, "Should use cached ranges (same changedtick)")
print("✓ Second fold used cache")

-- Test 4: Edit buffer and fold should re-detect
print("\nTest 4: Edit buffer (should invalidate cache)...")
vim.api.nvim_buf_set_lines(bufnr, 0, 1, false, {"-- Modified comment"})
local tick_after_edit = vim.api.nvim_buf_get_changedtick(bufnr)
assert(tick_after_edit ~= initial_tick, "Changedtick should change after edit")

plugin.unfold()
plugin.fold()
local state4 = plugin._state[bufnr]
assert(state4.folded, "Should be folded")
assert(state4.changedtick == tick_after_edit, "Should have new changedtick")
print("✓ Cache invalidated after edit, ranges re-detected")

-- Test 5: Multiple toggles without edits should use cache
print("\nTest 5: Multiple toggles (should use cache)...")
local current_tick = vim.api.nvim_buf_get_changedtick(bufnr)
for i = 1, 5 do
    plugin.toggle()
    local state = plugin._state[bufnr]
    assert(state.changedtick == current_tick, "Changedtick should remain same during toggles")
end
print("✓ Multiple toggles used cache correctly")

print("\n✓ All caching tests passed!")
vim.cmd("qall!")
