--[[
  Merges (deep) one table into another
]]
local modname = ...

---merge content of newVal into into. this is deep traversal where
---to into is being add or set the content of newVal
---@param into table to merge data into
---@param newVal table to merge the data from
local function mergeTbls(into, newVal)
  for k, v in pairs(newVal) do
    if type(v) == "table" then
      into[k] = into[k] or {}
      mergeTbls(into[k], v)
    else
      into[k] = v
    end
  end
end

---merge content of newVal into into. this is deep traversal where
---to into is being add or set the content of newVal
---@param into table to merge data into
---@param newVal table to merge the data from
local function main(into, newVal)
  package.loaded[modname] = nil
  mergeTbls(into, newVal)
end

return main
