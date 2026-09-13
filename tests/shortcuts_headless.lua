-- nvim --headless -u NONE -l tests/shortcuts_headless.lua
--
-- Note: this can't assert the post-pick mode. labels.insert_char_shortcut()
-- ends with :startinsert, which Neovim applies on the next real input cycle;
-- under a -l script there's no such cycle, so mode() still reads "n" here
-- even though it correctly reads "i" under real key-driven use (verified
-- interactively).

vim.opt.runtimepath:prepend(vim.fn.getcwd())
local labels = require("nvim-labels")
local label = require("nvim-labels.label")

local failures = 0
local function check(name, cond, extra)
  print((cond and "ok   - " or "FAIL - ") .. name .. (cond and "" or (" (" .. tostring(extra) .. ")")))
  if not cond then
    failures = failures + 1
  end
end

labels.setup({ char_shortcuts = { "→", "λ", "•" } })

local buf = vim.api.nvim_create_buf(true, false)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "hello world" })
vim.api.nvim_win_set_buf(0, buf)
vim.api.nvim_win_set_cursor(0, { 1, 5 }) -- right after "hello"

local ll = label.generate(3, require("nvim-labels.config").options.keys)
vim.api.nvim_feedkeys(ll[2], "t", false) -- pick the 2nd char
labels.insert_char_shortcut()

local line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
check("inserts the picked char at the cursor", line == "hello\xce\xbb world", vim.inspect(line))
check("cursor lands right after it", vim.deep_equal(vim.api.nvim_win_get_cursor(0), { 1, 7 }))

-- Esc cancels: no insertion.
vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "hello world" })
vim.api.nvim_win_set_cursor(0, { 1, 5 })
vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "t", false)
labels.insert_char_shortcut()
check("esc leaves the buffer untouched", vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == "hello world")

-- `<cursor>` marker: stripped from the inserted text, cursor lands there
-- instead of after the whole insertion.
labels.setup({ char_shortcuts = { "(<cursor>)" } })
vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "hello world" })
vim.api.nvim_win_set_cursor(0, { 1, 5 })
local ll2 = label.generate(1, require("nvim-labels.config").options.keys)
vim.api.nvim_feedkeys(ll2[1], "t", false)
labels.insert_char_shortcut()
check("<cursor> marker is stripped from the inserted text", vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == "hello() world")
check("cursor lands where the marker was", vim.deep_equal(vim.api.nvim_win_get_cursor(0), { 1, 6 }))

-- Multi-line entry (contains "\n"): splits into buffer lines instead of
-- erroring on nvim_buf_set_text ("replacement string item contains newlines").
labels.setup({ char_shortcuts = { "if true then\n<cursor>\nend" } })
vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "  before" })
vim.api.nvim_win_set_cursor(0, { 1, 8 }) -- end of "  before"
local ll3 = label.generate(1, require("nvim-labels.config").options.keys)
vim.api.nvim_feedkeys(ll3[1], "t", false)
labels.insert_char_shortcut()
local ml = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
check(
  "multi-line entry inserts one buffer line per \\n",
  vim.deep_equal(ml, { "  beforeif true then", "", "end" }),
  vim.inspect(ml)
)
check("cursor lands on the marker's line", vim.deep_equal(vim.api.nvim_win_get_cursor(0), { 2, 0 }))

-- Table entry { char, name }: `char` drives insertion (and the <cursor>
-- marker within it), `name` is only ever a display concern.
labels.setup({ char_shortcuts = { { char = "(<cursor>)", name = "paren" } } })
vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "hello world" })
vim.api.nvim_win_set_cursor(0, { 1, 5 })
local ll4 = label.generate(1, require("nvim-labels.config").options.keys)
vim.api.nvim_feedkeys(ll4[1], "t", false)
labels.insert_char_shortcut()
check(
  "table entry inserts `char`, not `name`",
  vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == "hello() world",
  vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
)
check("table entry's <cursor> marker still works", vim.deep_equal(vim.api.nvim_win_get_cursor(0), { 1, 6 }))

-- Malformed entries (not a string, or a table missing a string `char`) are
-- skipped with a warning; the well-formed entries around them still work.
labels.setup({ char_shortcuts = { "!", { name = "no char field" }, 42, "@" } })
vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "hello world" })
vim.api.nvim_win_set_cursor(0, { 1, 5 })
local ll5 = label.generate(2, require("nvim-labels.config").options.keys) -- 2 valid entries survive
vim.api.nvim_feedkeys(ll5[2], "t", false) -- pick the 2nd surviving entry ("@")
labels.insert_char_shortcut()
check(
  "malformed entries are skipped, valid ones still pickable",
  vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == "hello@ world",
  vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
)

-- No `char_shortcuts` configured: warns, doesn't error.
labels.setup({ char_shortcuts = {} })
check("empty `char_shortcuts` does not error", pcall(labels.insert_char_shortcut))

print(failures == 0 and "all passed" or failures .. " failure(s)")
os.exit(failures == 0 and 0 or 1)
