-- nvim --headless -u NONE -l tests/jump_headless.lua

vim.opt.runtimepath:prepend(vim.fn.getcwd())
local labels = require("nvim-labels")
local targets = require("nvim-labels.targets")
local label = require("nvim-labels.label")
labels.setup({})

local failures = 0
local function check(name, cond, extra)
  print((cond and "ok   - " or "FAIL - ") .. name .. (cond and "" or (" (" .. tostring(extra) .. ")")))
  if not cond then
    failures = failures + 1
  end
end

local function scratch(lines)
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_win_set_buf(0, buf)
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  return buf
end

-- Word starts, cursor word excluded.
scratch({ "alpha beta gamma", "delta epsilon zeta", "eta theta iota kappa" })
local list = targets.collect(0)
check("collect skips the cursor word", #list == 9, #list)

-- Single-key label jumps to a word start.
vim.api.nvim_feedkeys("f", "t", false)
labels.jump()
local pos = vim.api.nvim_win_get_cursor(0)
local landed = vim.api.nvim_buf_get_lines(0, pos[1] - 1, pos[1], false)[1]:sub(pos[2] + 1):match("^[%w_]+")
check("single-key label jumps to a word start", landed ~= nil and not (pos[1] == 1 and pos[2] == 0), vim.inspect(pos))

-- Multi-key label jumps to its exact target.
do
  local lines = {}
  for i = 1, 12 do
    lines[i] = "word" .. i .. " item" .. i .. " node" .. i
  end
  scratch(lines)
  local t = targets.collect(0)
  targets.sort_by_distance(t, 0, 0)
  local ll = label.generate(#t, require("nvim-labels.config").options.keys)
  local pick
  for i, lab in ipairs(ll) do
    if #lab == 2 then
      pick = { label = lab, tgt = t[i] }
      break
    end
  end
  check("some label needs 2 keys", pick ~= nil)
  vim.api.nvim_feedkeys(pick.label, "t", false)
  labels.jump()
  local p = vim.api.nvim_win_get_cursor(0)
  check("2-key label jumps to its target", p[1] - 1 == pick.tgt.row and p[2] == pick.tgt.col, vim.inspect(p))
end

-- Subword targets: camelCase, snake_case, kebab-case, acronym boundaries.
scratch({ "fooBar baz_qux one-two HTMLElement", "cursor line" })
vim.api.nvim_win_set_cursor(0, { 2, 0 })
local cols = {}
for _, t in ipairs(targets.collect(0)) do
  if t.row == 0 then
    cols[#cols + 1] = t.col
  end
end
check(
  "splits on case / _ / - and acronyms",
  vim.deep_equal(cols, { 0, 3, 7, 11, 15, 19, 23, 27 }),
  vim.inspect(cols)
)

do
  require("nvim-labels.config").options.subwords = false
  local plain = {}
  for _, t in ipairs(targets.collect(0)) do
    if t.row == 0 then
      plain[#plain + 1] = t.col
    end
  end
  check("subwords = false -> plain word starts", vim.deep_equal(plain, { 0, 7, 15, 19, 23 }), vim.inspect(plain))
  require("nvim-labels.config").options.subwords = true
end

-- Esc cancels without moving.
scratch({ "alpha beta gamma" })
vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "t", false)
labels.jump()
local p = vim.api.nvim_win_get_cursor(0)
check("esc leaves the cursor put", p[1] == 1 and p[2] == 0, vim.inspect(p))

-- Empty buffer does not error.
scratch({})
check("empty buffer does not error", pcall(labels.jump))

-- Highlights survive :colorscheme (which runs :hi clear).
vim.cmd("colorscheme blue")
check("LabelPick re-applied after colorscheme", next(vim.api.nvim_get_hl(0, { name = "LabelPick" })) ~= nil)

print(failures == 0 and "all passed" or failures .. " failure(s)")
os.exit(failures == 0 and 0 or 1)
