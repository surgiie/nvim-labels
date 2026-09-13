local M = {}

local CANCEL = { ["\27"] = true, ["\3"] = true, [""] = true }
local BACKSPACE = { [vim.keycode("<BS>")] = true, ["\8"] = true, ["\127"] = true }

-- Read keys, narrowing `items` (anything with a .label) until one is picked.
-- Calls `render(prefix)` after every key. Returns the chosen item, or nil if
-- cancelled. Labels are assumed prefix-free, so an exact match is unambiguous.
function M.run(items, render)
  local prefix = ""
  while true do
    local ok, ch = pcall(vim.fn.getcharstr)
    if not ok or CANCEL[ch] then
      return nil
    end

    if BACKSPACE[ch] then
      prefix = prefix:sub(1, -2)
    else
      local candidate = prefix .. ch
      local any = false
      for _, it in ipairs(items) do
        if it.label == candidate then
          return it
        end
        any = any or it.label:sub(1, #candidate) == candidate
      end
      if not any then
        return nil
      end
      prefix = candidate
    end

    render(prefix)
  end
end

return M
