--[[
Right padding a string with a character.
]]

local modname = ...

---@param str string
---@param len integer
---@param char string
---@return string
local function main(str, len, char)
  package.loaded[modname] = nil

  str = str or ""
  len = len or 0
  char = char or " "

  if len <= #str then
    return str
  end

  return str .. string.rep(char, len - #str)
end

return main