--[[
  Reads device configuration stored in "device-config.json".

  Any unset KEY value is replaced with empty string.

  See "factory_settings" for more info.
  See "device-config.json" for data structure info.

  Use this module to load the configuation and use it wherever needed.

  Usage:
    local cfg = require("device_settings")
    print(cfg.wifi.country.country) -- prints device country
]]
local modname = ...

local function readJsonFile(fName)
  package.loaded[modname] = nil

  local fName = "device-settings.json"
  local file, sjson = require("file"), require("sjson")
  local txt = file.getcontents(fName)
  return sjson.decode(txt)
end

return readJsonFile(fName)
