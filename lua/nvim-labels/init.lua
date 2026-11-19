local config = require("nvim-labels.config")
local targets = require("nvim-labels.targets")
local label = require("nvim-labels.label")
local view = require("nvim-labels.view")
local input = require("nvim-labels.input")
local shortcuts = require("nvim-labels.shortcuts")

local M = {}
local active = false

function M.setup(opts)
  config.setup(opts)
end

M.insert_char_shortcut = shortcuts.insert_char_shortcut

---Show hints in the current window and read keys until one is chosen.
---@return table|nil chosen target ({ row, col, stop }, 0-indexed, stop exclusive); nil if cancelled or none
---@return integer[]|nil cursor cursor at pick time, as nvim_win_get_cursor
local function pick()
  if active then
    return nil
  end

  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_win_get_buf(win)
  local cursor = vim.api.nvim_win_get_cursor(win)

  local list = targets.collect(win)
  if #list == 0 then
    vim.notify("nvim-labels: no targets in view", vim.log.levels.WARN)
    return nil
  end

  targets.sort_by_distance(list, cursor[1] - 1, cursor[2])
  local label_list = label.generate(#list, config.options.keys)
  for i, t in ipairs(list) do
    t.label = label_list[i]
  end

  local n = vim.api.nvim_buf_line_count(buf)
  local state = {
    buf = buf,
    top = math.max(1, math.min(vim.fn.line("w0"), n)),
    bot = math.max(1, math.min(vim.fn.line("w$"), n)),
    targets = list,
  }

  active = true
  local ok, chosen = pcall(function()
    view.render(state, "")
    return input.run(state.targets, function(prefix)
      view.render(state, prefix)
    end)
  end)
  view.clear(buf)
  vim.cmd("redraw")
  active = false
  assert(ok, chosen)

  return chosen, cursor
end

function M.jump()
  local chosen = pick()
  if not chosen then
    return
  end

  if config.options.jumplist then
    vim.cmd("normal! m'")
  end
  vim.api.nvim_win_set_cursor(0, { chosen.row + 1, chosen.col })
end

---Delete charwise between the cursor and a hinted word, including that word.
---To the right the range runs through the end of the word; to the left it
---runs from the word's start up to, not including, the cursor character.
---Goes through visual mode + `d`, so it fills the unnamed register and is one
---undo step.
function M.delete()
  local chosen, cursor = pick()
  if not chosen or not cursor then
    return
  end

  local cursor_row, cursor_col = cursor[1] - 1, cursor[2]
  local target_is_before = chosen.row < cursor_row or (chosen.row == cursor_row and chosen.col < cursor_col)
  local start_row, start_col, end_row, end_col
  if target_is_before then
    start_row, start_col, end_row, end_col = chosen.row, chosen.col, cursor_row, cursor_col
  else
    start_row, start_col, end_row, end_col = cursor_row, cursor_col, chosen.row, chosen.stop
  end

  if start_row == end_row and start_col == end_col then
    return
  end

  local original_selection = vim.o.selection
  vim.o.selection = "inclusive"
  local ok, err = pcall(function()
    vim.api.nvim_win_set_cursor(0, { start_row + 1, start_col })
    vim.cmd("normal! v")
    if end_col > 0 then
      vim.api.nvim_win_set_cursor(0, { end_row + 1, end_col - 1 })
    else
      -- Exclusive end at column 0: the last deleted character is the previous
      -- line's line break, which `$` in visual mode includes.
      vim.api.nvim_win_set_cursor(0, { end_row, 0 })
      vim.cmd("normal! $")
    end
    vim.cmd("normal! d")
  end)
  vim.o.selection = original_selection
  assert(ok, err)
end

return M
