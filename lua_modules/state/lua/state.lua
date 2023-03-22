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
---simple wrapper for getting access to global var representing RTE state of various modules
---it is a plain table where each field represent a module data.
---@type table
local M = {}

---returns the state for given module or defVal if no such yet defined.
---returns entire state table of no modname is given
---@param modname? string state of the given module
---@param defVal? table? default data if module has no state defined yet
---@param noDef? boolean if true, default value is not auto-created. used when trying to test for existing key.
---@return table
local function main(modname, defVal, noDef)
  if not modname then
    return M
  end
  local s = M[modname]
  if not (s or noDef) then
    s = defVal or {}
    M[modname] = s
  end
  return s
end

return main
