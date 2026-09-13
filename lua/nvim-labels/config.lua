local M = {}

local defaults = {
  keys = "fjdkslaghrueiwotnvbc",
  pattern = "[%w_]+",
  subwords = true, -- also target camelCase / snake_case / kebab-case parts
  dim = true,
  jumplist = true,
  exclude_cursor_word = true,
  char_shortcuts = {}, -- characters for labels.insert_char_shortcut(), e.g. your keyboard's layer 2
}

M.options = vim.deepcopy(defaults)

function M.setup_highlights()
  -- Colours from ~/.config/wl-kbptr (Catppuccin Mocha, tile mode).
  vim.api.nvim_set_hl(0, "LabelPick", { fg = "#ffffff", bg = "#1e1e2e", bold = true, default = true })
  vim.api.nvim_set_hl(0, "LabelDim", { fg = "#585b70", default = true })
end

-- :colorscheme runs :hi clear, so re-apply on every ColorScheme too.
M.setup_highlights()
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("labels.highlights", { clear = true }),
  callback = M.setup_highlights,
})

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})
  M.setup_highlights()
end

return M
