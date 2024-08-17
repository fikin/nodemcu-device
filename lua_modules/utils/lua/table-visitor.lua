--[[
Table pairs visitor in sorted way
]]

local modname = ...

---visit table pairs
---@param tbl table
---@param fn fun(k:any,v:any)
local function main(tbl, fn)
  package.loaded[modname] = nil

  local lst = require("table-getkeys")(tbl, true)
  for _, k in pairs(lst) do
    fn(k, tbl[k])
  end
end

return main
