--[[
  A simple table.

  Require will keep it cached in loaded modules.

  The idea is to use that table to keep some small amounts of RTE data
  and allow other modules to be garbage collected.

  Usage:
    require("state")(<modname>) returns always a table with data
    require("state")(<modname>,defValue) initializes the table with defVal if not existing already
    require("state")() returns entire state object
]]
local M = {}

local function main(modname, defVal)
  if not modname then
    return M
  end
  local s = M[modname]
  if not s then
    s = defVal or {}
    M[modname] = s
  end
  return s
end

return main
