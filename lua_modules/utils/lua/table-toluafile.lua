--[[
Saves a table as a lua file (compiled lc).
]]
local modname = ...

---save table as lua file
---if compile is true, saves as compiled lua file
---@param name string
---@param tbl table
---@param compile boolean generate .lc file
---@param gc boolean gc from package.loaded after call
local function main(name, tbl, compile, gc)
  package.loaded[modname] = nil -- gc

  require("save-func")(name, require("table-tostring")(tbl), compile, gc)
end

return main
