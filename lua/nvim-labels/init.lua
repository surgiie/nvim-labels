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

function M.jump()
  if active then
    return
  end

  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_win_get_buf(win)
  local cursor = vim.api.nvim_win_get_cursor(win)

  local list = targets.collect(win)
  if #list == 0 then
    vim.notify("nvim-labels: no targets in view", vim.log.levels.WARN)
    return
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

  if chosen then
    if config.options.jumplist then
      vim.cmd("normal! m'")
    end
    vim.api.nvim_win_set_cursor(win, { chosen.row + 1, chosen.col })
  end
end

return M
