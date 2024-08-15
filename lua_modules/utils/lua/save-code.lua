--[[
Save given code as lua file, which one can call with `require`.
]]

local modname = ...

---save code as lua file
---if compile is true, saves as compiled lua file
---@param name string
---@param code string
---@param compile boolean generate .lc file
local function main(name, code, compile)
  package.loaded[modname] = nil

  local file = require("file")

  local fLua = name .. ".lua"
  file.putcontents(fLua, code)
  if compile then
    require("node").compile(fLua)
  end
end

return main
