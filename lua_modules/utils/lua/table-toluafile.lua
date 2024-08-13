--[[
Saves a table as a lua file (compiled lc).
]]
local modname = ...

---save table as lua file
---if compile is true, saves as compiled lua file
---@param name string
---@param tbl table
---@param compile boolean
local function main(name, tbl, compile)
  package.loaded[modname] = nil -- gc

  local file = require("file")

  local fLua = name .. ".lua"
  file.putcontents(fLua, "return " .. require("table-tostring")(tbl))
  if compile then
    require("node").compile(fLua)
  end
end

return main
