--[[
  Merges (deep) one table into another
]]
local modname = ...

local function mergeTbls(into, newVal)
  for k, v in pairs(newVal) do
    if type(v) == table then
      -- recursive navigation of tables
      into[k] = into[k] or {}
      mergeTbls(into[k], v)
    else
      into[k] = v
    end
  end
end

local function main(into, newVal)
  package.loaded[modname] = nil
  mergeTbls(into, newVal)
end

return main
