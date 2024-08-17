--[[
Save given text as lua function, which one can call with `require`.
]]

local modname = ...

---@param code string
---@return string
local function returnPlain(code)
  return "return " .. code
end

---@param code string
---@return string
local function returnGc(code)
  return [[
local modname = ...
local function main()
  package.loaded[modname] = nil
  return ]] .. code .. [[

end
return main
]]
end

---save table as lua file
---if compile is true, saves as compiled lua file
---@param name string
---@param code string
---@param compile boolean generate .lc file
---@param gc boolean gc from package.loaded after call
local function main(name, code, compile, gc)
  package.loaded[modname] = nil

  require("save-code")(name, gc and returnGc(code) or returnPlain(code), compile)
end

return main
