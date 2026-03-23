local M = {}

local function get_date()
  return os.date '%d.%m.%Y'
end

-- Check if a line is a top-level todo item (not indented)
local function is_todo_item(line)
  return line:match '^%- %[[ x]%]' ~= nil
end

-- Find all sub-lines belonging to a todo item (indented lines following it)
local function get_item_block(buf, start_lnum)
  local lines = vim.api.nvim_buf_get_lines(buf, start_lnum - 1, -1, false)
  local block = { lines[1] }
  for i = 2, #lines do
    local line = lines[i]
    -- Sub-items are indented (start with spaces)
    if line:match '^%s+' then
      table.insert(block, line)
    else
      break
    end
  end
  return block
end

-- Find the line number of the "## Done" section header
local function find_done_section(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  for i, line in ipairs(lines) do
    if line:match '^## Done' then
      return i
    end
  end
  return nil
end

function M.mark_done()
  local buf = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local lnum = cursor[1]

  -- Walk up to find the parent todo item if cursor is on a sub-item
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local item_lnum = lnum
  while item_lnum > 1 and not is_todo_item(lines[item_lnum]) do
    item_lnum = item_lnum - 1
  end

  if not is_todo_item(lines[item_lnum]) then
    vim.notify('No todo item found on this line', vim.log.levels.WARN)
    return
  end

  -- Get the full block (item + sub-lines)
  local block = get_item_block(buf, item_lnum)

  -- Mark as done and append date to the first line
  local date = get_date()
  block[1] = block[1]:gsub('%[ %]', '[x]', 1)
  -- Remove any existing date tag, then append new one
  block[1] = block[1]:gsub('%s*%-%-[%d%.]+$', '')
  block[1] = block[1] .. ' --' .. date

  -- Find ## Done section
  local done_lnum = find_done_section(buf)
  if not done_lnum then
    vim.notify("No '## Done' section found in buffer", vim.log.levels.ERROR)
    return
  end

  -- Delete the original block from the buffer
  vim.api.nvim_buf_set_lines(buf, item_lnum - 1, item_lnum - 1 + #block, false, {})

  -- Recalculate done section position after deletion
  done_lnum = find_done_section(buf)

  -- Insert the block right after the ## Done header
  vim.api.nvim_buf_set_lines(buf, done_lnum, done_lnum, false, block)

  vim.notify('Moved to Done: ' .. block[1])
end

-- function M.setup(opts)
--   opts = opts or {}
--   local key = opts.keybind or '<leader>td'
--   vim.keymap.set('n', key, M.mark_done, {
--     desc = 'Mark todo item as done and move to Done section',
--     silent = true,
--   })
-- end

return {
  name = 'todo_done',
  dir = vim.fn.stdpath 'config', -- points to ~/.config/nvim
  config = function()
    vim.keymap.set('n', '<leader>td', M.mark_done, {
      desc = 'Mark todo item as done and move to Done section',
      silent = true,
    })
  end,
}
