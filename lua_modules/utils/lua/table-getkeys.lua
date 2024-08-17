--[[
Get table keys, possibly in sorted way
]]

local modname = ...

---return table kets
---@param tbl table[string:any]
---@return string[]
local function getKeys(tbl)
  local ret = {}
  for k, _ in pairs(tbl) do
    table.insert(ret, k)
  end
  return ret
end

---get table keys, possibly in sorted way
---@param tbl table
---@param sorted boolean
---@return string[]
local function main(tbl, sorted)
  package.loaded[modname] = nil

  local lst = getKeys(tbl)
  if sorted then
    table.sort(lst)
  end
  return lst
end

return main
