-- Label-jump picker for `config.options.char_shortcuts`: a floating window lists each
-- configured character behind a label, arranged in a grid so the window grows
-- wide instead of tall. Picking one inserts it at the cursor and leaves you
-- in insert mode, whichever mode you invoked it from.
--
-- An entry may contain a `<cursor>` marker (e.g. "(<cursor>)"): it's stripped
-- from the inserted text and the cursor lands where it was, instead of after
-- the whole insertion. An entry may also span multiple lines ("\n"); each
-- line is inserted as its own buffer line, and the marker can be on any of
-- them.
--
-- An entry may also be a table `{ char = "...", name = "..." }` instead of a
-- plain string: `char` is still what gets inserted, but the grid shows `name`
-- in its place. Meant for entries whose real text would otherwise wreck the
-- grid's width (a multi-line snippet, a long one) — e.g.
-- `{ char = "if true then\n<cursor>\nend", name = "if" }`.

local config = require("nvim-labels.config")
local label = require("nvim-labels.label")
local input = require("nvim-labels.input")

local M = {}
local ns = vim.api.nvim_create_namespace("nvim-labels.shortcuts")
local active = false
local MAX_COLS = 8
local LEFT_PAD = 2
local CELL_GAP = 3
local CURSOR_MARKER = "<cursor>"

-- How many columns and how wide each cell should be (in display cells, not
-- bytes -- a multi-byte char like "⏎" takes fewer screen columns than bytes,
-- and padding on byte count alone throws off alignment on any row that has
-- one).
local function grid(items)
  local cols = math.min(#items, MAX_COLS)
  local cell_w = 0
  for _, it in ipairs(items) do
    local w = vim.fn.strdisplaywidth(it.label) + 1 + vim.fn.strdisplaywidth(it.display)
    cell_w = math.max(cell_w, w)
  end
  return cols, cell_w
end

local function render(buf, items, prefix, cols, cell_w)
  local lines, cells = {}, {}

  for i = 1, #items, cols do
    local parts, row_cells, col = {}, {}, LEFT_PAD
    for j = i, math.min(i + cols - 1, #items) do
      local it = items[j]
      local text = ("%s %s"):format(it.label, it.display)
      local pad = math.max(0, cell_w - vim.fn.strdisplaywidth(text))
      local cell_text = text .. (" "):rep(pad)
      parts[#parts + 1] = cell_text
      row_cells[#row_cells + 1] = { it = it, col = col, len = #cell_text }
      col = col + #cell_text + CELL_GAP
    end
    lines[#lines + 1] = (" "):rep(LEFT_PAD) .. table.concat(parts, (" "):rep(CELL_GAP))
    cells[#cells + 1] = row_cells
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for row, row_cells in ipairs(cells) do
    for _, c in ipairs(row_cells) do
      if c.it.label:sub(1, #prefix) == prefix then
        vim.api.nvim_buf_add_highlight(buf, ns, "LabelPick", row - 1, c.col, c.col + #c.it.label)
      else
        vim.api.nvim_buf_add_highlight(buf, ns, "LabelDim", row - 1, c.col, c.col + c.len)
      end
    end
  end
  vim.cmd("redraw")
end

-- Split `char` into buffer lines (on "\n"), stripping its (first) `<cursor>`
-- marker if present. Returns the lines to insert, plus where the cursor
-- should land within them: `marker_line` (0-indexed, relative to the first
-- inserted line) and `marker_col` (byte offset into that line). No marker ->
-- cursor after everything.
local function split_cursor_marker(char)
  local lines = vim.split(char, "\n", { plain = true })
  for i, line in ipairs(lines) do
    local s, e = line:find(CURSOR_MARKER, 1, true)
    if s then
      lines[i] = line:sub(1, s - 1) .. line:sub(e + 1)
      return lines, i - 1, s - 1
    end
  end
  return lines, #lines - 1, #lines[#lines]
end

-- Normalize one `char_shortcuts` entry to { char, display_source }, or nil if
-- it's malformed (a warning is issued either way isn't needed here — the
-- caller reports how many were skipped once, rather than once per entry).
-- `display_source` is what the grid shows (pre marker-strip/newline-collapse):
-- a table's `name` if given, else its `char` (or the string itself).
local function normalize_entry(ch)
  if type(ch) == "string" then
    return { char = ch, display_source = ch }
  end
  if type(ch) == "table" and type(ch.char) == "string" then
    return { char = ch.char, display_source = ch.name or ch.char }
  end
  return nil
end

function M.insert_char_shortcut()
  if active then
    return
  end
  local configured = config.options.char_shortcuts
  if not configured or #configured == 0 then
    vim.notify("nvim-labels: no `char_shortcuts` configured (see :h nvim-labels-setup)", vim.log.levels.WARN)
    return
  end

  local chars, skipped = {}, 0
  for _, ch in ipairs(configured) do
    local entry = normalize_entry(ch)
    if entry then
      chars[#chars + 1] = entry
    else
      skipped = skipped + 1
    end
  end
  if skipped > 0 then
    vim.notify(
      "nvim-labels: skipped "
        .. skipped
        .. " malformed `char_shortcuts` entr"
        .. (skipped == 1 and "y" or "ies")
        .. " (want a string, or a table with a string `char` field)",
      vim.log.levels.WARN
    )
  end
  if #chars == 0 then
    return
  end

  local label_list = label.generate(#chars, config.options.keys)
  local items = {}
  for i, entry in ipairs(chars) do
    -- Grid cells are one buffer line each, so a multi-line entry gets
    -- collapsed to a single line for display; only the actual insertion
    -- keeps its line breaks.
    local display = entry.display_source:gsub(CURSOR_MARKER, ""):gsub("\n", "⏎")
    items[i] = { char = entry.char, display = display, label = label_list[i] }
  end

  local cols, cell_w = grid(items)
  local rows = math.ceil(#items / cols)
  local width = LEFT_PAD + cols * cell_w + (cols - 1) * CELL_GAP + 2

  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, false, {
    relative = "cursor",
    row = 1,
    col = 0,
    width = width,
    height = rows,
    style = "minimal",
    border = "rounded",
  })

  active = true
  local ok, chosen = pcall(function()
    render(buf, items, "", cols, cell_w)
    return input.run(items, function(prefix)
      render(buf, items, prefix, cols, cell_w)
    end)
  end)
  if vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
  end
  active = false
  assert(ok, chosen)

  if chosen then
    local win0 = vim.api.nvim_get_current_win()
    local buf0 = vim.api.nvim_win_get_buf(win0)
    local cursor = vim.api.nvim_win_get_cursor(win0)
    local row, col = cursor[1] - 1, cursor[2]
    local lines, marker_line, marker_col = split_cursor_marker(chosen.char)
    vim.api.nvim_buf_set_text(buf0, row, col, row, col, lines)
    -- The marker's line is only offset by the insertion column when it's the
    -- first inserted line; later lines start fresh at column 0.
    local cursor_col = marker_col + (marker_line == 0 and col or 0)
    vim.api.nvim_win_set_cursor(win0, { row + marker_line + 1, cursor_col })
    if vim.fn.mode() ~= "i" then
      vim.cmd("startinsert")
    end
  end
end

return M
