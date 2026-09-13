-- Generate `n` prefix-free labels from an ordered key list, shortest first, so
-- callers can give the cheapest labels to the nearest targets.

local M = {}

local UTF8 = "[%z\1-\127\194-\244][\128-\191]*"

local function to_list(keys)
  if type(keys) == "table" then
    return keys
  end
  local list = {}
  for ch in keys:gmatch(UTF8) do
    list[#list + 1] = ch
  end
  return list
end

function M.generate(n, keys)
  local alphabet = to_list(keys)
  local k = #alphabet
  assert(k >= 2, "nvim-labels: `keys` needs at least 2 characters")
  if n <= 0 then
    return {}
  end

  local rank = {}
  for i, ch in ipairs(alphabet) do
    rank[ch] = i
  end

  local slots = {}
  for i = 1, k do
    slots[i] = alphabet[i]
  end

  -- Split the right-most shortest slot into k children until there are enough.
  while #slots < n do
    local min_len = math.huge
    for _, s in ipairs(slots) do
      min_len = math.min(min_len, #s)
    end
    local idx
    for i = #slots, 1, -1 do
      if #slots[i] == min_len then
        idx = i
        break
      end
    end
    local parent = table.remove(slots, idx)
    for i = 1, k do
      slots[#slots + 1] = parent .. alphabet[i]
    end
  end

  local function key_seq(label)
    local out = {}
    for ch in label:gmatch(UTF8) do
      out[#out + 1] = rank[ch] or math.huge
    end
    return out
  end
  table.sort(slots, function(a, b)
    if #a ~= #b then
      return #a < #b
    end
    local sa, sb = key_seq(a), key_seq(b)
    for i = 1, #sa do
      if sa[i] ~= sb[i] then
        return sa[i] < sb[i]
      end
    end
    return false
  end)

  local out = {}
  for i = 1, n do
    out[i] = slots[i]
  end
  return out
end

return M
