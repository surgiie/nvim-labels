-- nvim -l tests/label_spec.lua

package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"
local label = require("nvim-labels.label")

local failures = 0
local function check(name, cond)
  print((cond and "ok   - " or "FAIL - ") .. name)
  if not cond then
    failures = failures + 1
  end
end

local function prefix_free(list)
  for i = 1, #list do
    for j = 1, #list do
      if i ~= j and list[i]:sub(1, #list[j]) == list[j] then
        return false
      end
    end
  end
  return true
end

local function unique(list)
  local seen = {}
  for _, v in ipairs(list) do
    if seen[v] then
      return false
    end
    seen[v] = true
  end
  return true
end

do
  local l = label.generate(3, "fjdks")
  check("fits in one key -> single chars in order", #l == 3 and l[1] == "f" and l[2] == "j" and l[3] == "d")
end

do
  local l = label.generate(6, "fjd")
  local maxlen = 0
  for _, v in ipairs(l) do
    maxlen = math.max(maxlen, #v)
  end
  check("more targets than keys -> count", #l == 6)
  check("more targets than keys -> unique", unique(l))
  check("more targets than keys -> prefix-free", prefix_free(l))
  check("more targets than keys -> first stays single-key", #l[1] == 1)
  check("more targets than keys -> nothing longer than 2", maxlen <= 2)
end

do
  local l = label.generate(100, "fj")
  check("large n -> count", #l == 100)
  check("large n -> unique", unique(l))
  check("large n -> prefix-free", prefix_free(l))
end

do
  check("n <= 0 -> empty", #label.generate(0, "fj") == 0)
  check("single-key alphabet -> error", not pcall(label.generate, 5, "f"))
end

print(failures == 0 and "all passed" or failures .. " failure(s)")
os.exit(failures == 0 and 0 or 1)
