--[[
Print table as multi-line string.
]]

local modname = ...

local lpad = require("lpad")

---serialize table to string
---@param arr string[]
---@param indent number
---@param o any
local function serialize(arr, indent, o)
  if type(o) == "number" then
    table.insert(arr, o)
  elseif type(o) == "string" then
    table.insert(arr, string.format("%q", o))
  elseif type(o) == "boolean" then
    table.insert(arr, tostring(o))
  elseif type(o) == "nil" then
    table.insert(arr, "nil")
  elseif type(o) == "table" then
    table.insert(arr, "{")
    require("table-visitor")(o, function(k, v)
      table.insert(arr, "\n")
      table.insert(arr, lpad("", indent + 1, " "))
      table.insert(arr, "[")
      serialize(arr, indent + 1, k)
      table.insert(arr, "] = ")
      serialize(arr, indent + 1, v)
      table.insert(arr, ",")
    end)
    if indent > 0 then -- nested tables
      table.insert(arr, "\n")
      table.insert(arr, lpad("", indent, " "))
      table.insert(arr, "}")
    else -- first table
      table.insert(arr, "\n}")
    end
  else
    error("cannot serialize a " .. type(o))
  end
end

local function main(tbl)
  package.loaded[modname] = nil -- gc

  local arr = {}
  serialize(arr, 0, tbl)
  return table.concat(arr, "")
end

return main
