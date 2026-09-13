local config = require("nvim-labels.config")

local M = {}

local function is_lower(b)
  return b and b >= 97 and b <= 122
end
local function is_upper(b)
  return b and b >= 65 and b <= 90
end
local function is_digit(b)
  return b and b >= 48 and b <= 57
end

-- Byte offsets (0-indexed) where a sub-word begins inside `chunk`: after "_" or
-- "-", and at camelCase / PascalCase boundaries. Mirrors nvim-spider's motion.
local function subword_starts(chunk)
  local starts, prev = {}, nil
  for i = 1, #chunk do
    local b = chunk:byte(i)
    if b == 95 or b == 45 then -- "_" / "-": delimiters, never a target
      prev = nil
    else
      local nb = chunk:byte(i + 1)
      local boundary = prev == nil
        or ((is_lower(prev) or is_digit(prev)) and is_upper(b)) -- fooBar
        or (is_upper(prev) and is_upper(b) and is_lower(nb)) -- HTMLElement
      if boundary then
        starts[#starts + 1] = i - 1
      end
      prev = b
    end
  end
  return starts
end

-- Target positions ({ row, col }, 0-indexed) in the visible area of `win`:
-- the start of each `pattern` chunk, split by `subwords` when enabled.
function M.collect(win)
  win = win or vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_win_get_buf(win)
  local opts = config.options
  local targets = {}

  vim.api.nvim_win_call(win, function()
    local top = vim.fn.line("w0")
    local bot = vim.fn.line("w$")
    local leftcol = vim.fn.winsaveview().leftcol or 0
    local width = vim.api.nvim_win_get_width(win) - ((vim.fn.getwininfo(win)[1] or {}).textoff or 0)
    local wrap = vim.wo[win].wrap
    local cursor = vim.api.nvim_win_get_cursor(win)
    local cur_row, cur_col = cursor[1] - 1, cursor[2]

    for i, line in ipairs(vim.api.nvim_buf_get_lines(buf, top - 1, bot, false)) do
      local lnum = top - 1 + i
      if vim.fn.foldclosed(lnum) == -1 then
        local row, col = lnum - 1, 1
        while true do
          local s, e = line:find(opts.pattern, col)
          if not s then
            break
          end
          e = e or s
          local chunk = line:sub(s, e)
          local offsets = opts.subwords and subword_starts(chunk) or { 0 }
          for j, off in ipairs(offsets) do
            local start = s - 1 + off
            local stop = s - 1 + (offsets[j + 1] or #chunk) -- exclusive
            local hidden = not wrap and (start < leftcol or start >= leftcol + width)
            local on_cursor = opts.exclude_cursor_word
              and row == cur_row
              and cur_col >= start
              and cur_col < stop
            if not hidden and not on_cursor then
              targets[#targets + 1] = { row = row, col = start }
            end
          end
          col = e + 1
        end
      end
    end
  end)

  return targets
end

-- Sort in place, nearest to (cur_row, cur_col) first.
function M.sort_by_distance(targets, cur_row, cur_col)
  table.sort(targets, function(a, b)
    local da = math.abs(a.row - cur_row) * 1000 + math.abs(a.col - cur_col)
    local db = math.abs(b.row - cur_row) * 1000 + math.abs(b.col - cur_col)
    if da ~= db then
      return da < db
    end
    if a.row ~= b.row then
      return a.row < b.row
    end
    return a.col < b.col
  end)
end

return M
