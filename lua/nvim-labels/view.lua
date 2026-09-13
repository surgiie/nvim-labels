local config = require("nvim-labels.config")

local M = {}
local ns = vim.api.nvim_create_namespace("nvim-labels")

-- Draw a label over every target whose label starts with `prefix`, showing only
-- the not-yet-typed part. Dims the rest of the visible area when enabled.
function M.render(state, prefix)
  M.clear(state.buf)

  if config.options.dim then
    local last = vim.api.nvim_buf_get_lines(state.buf, state.bot - 1, state.bot, false)[1] or ""
    vim.api.nvim_buf_set_extmark(state.buf, ns, state.top - 1, 0, {
      end_row = state.bot - 1,
      end_col = #last,
      hl_group = "LabelDim",
      hl_eol = true,
      priority = 100,
    })
  end

  for _, t in ipairs(state.targets) do
    if t.label:sub(1, #prefix) == prefix then
      vim.api.nvim_buf_set_extmark(state.buf, ns, t.row, t.col, {
        virt_text = { { t.label:sub(#prefix + 1), "LabelPick" } },
        virt_text_pos = "overlay",
        hl_mode = "combine",
        priority = 65535,
      })
    end
  end

  vim.cmd("redraw")
end

function M.clear(buf)
  vim.api.nvim_buf_clear_namespace(buf or 0, ns, 0, -1)
end

return M
