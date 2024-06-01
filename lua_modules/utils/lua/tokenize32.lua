local modname = ...

---tokenize 32bits into 4x8bits
---@param val32 number 32bits
---@return number 1st 8bits
---@return number 2nd 8bits
---@return number 3rd 8bits
---@return number 4th 8bits
local function main(val32)
  package.loaded[modname] = nil

  local bit = require("bit")

  local b1 = bit.band(val32, 0xFF)
  val32 = bit.rshift(val32, 8)
  local b2 = bit.band(val32, 0xFF)
  val32 = bit.rshift(val32, 8)
  local b3 = bit.band(val32, 0xFF)
  local b4 = bit.rshift(val32, 8)
  return b4, b3, b2, b1
end

return main
