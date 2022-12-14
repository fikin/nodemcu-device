--[[
  Reads device configuration stored in "device-settings.json".

  See "factory_settings" for more info.
  See "device-config.json" for data structure info.

  Use this module to read configuation and use it wherever needed.

  Usage:
    local cfg = require("device_settings")()
    print(cfg.wifi.country.country) -- prints device country
]]
local M = require("read_json_file")("device-settings.json")

local function main(modname, defVal)
  package.loaded[modname] = nil

  if not modname then
    return M
  end
  local s = M[modname]
  if not s then
    return defVal
  end
  return s
end

return main
