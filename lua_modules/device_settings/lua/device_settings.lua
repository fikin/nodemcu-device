--[[
  Reads device configuration stored in "device-settings.json".

  See "factory_settings" for more info.
  See "device-config.json" for data structure info.

  Use this module to read configuation and use it wherever needed.

  Usage:
    local cfg = require("device_settings")()
    print(cfg.wifi.country.country) -- prints device country
]]
local modname = ...

local M = require("read_json_file")("device-settings.json")

---read device-settings.json and returns either a modname (first level attribute) or entire content
---@param field? string to return its value i.e. settings.field or defVal if not existing
---@param defVal? any to return in case settings.field does not exists
---@return table is the value of settings.field or defVal
local function main(field, defVal)
  package.loaded[modname] = nil

  if not field then
    return M
  end
  local s = M[field]
  if not s then
    return defVal
  end
  return s
end

return main
