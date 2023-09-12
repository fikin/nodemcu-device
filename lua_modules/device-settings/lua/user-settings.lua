--[[
  Add here device settings which you want to apply programmatically at boot time.
  
  Use builder:set("field path", value) to set a value.
  
  Use builder:unset("field path") to set a field to nil.

  Use builder:default("field path", value) to assign some value, if not assigned already.
  This setting would take effect only if default-settings.json value is either:
  - not defined
  - empty string
  - string containing "<something>" format
  In all other cases (values), the value would not be changed.
  ]]
local modname = ...

local fs = require("factory-settings")

---place to provide with device specific hardcoded device settings.
---feel free to modify the settings here, boot sequence will ensure
---the data is properly handled in device settings.
local function main()
  package.loaded[modname] = nil

  -- typically set hostname is based on chipID
  -- until user overwrites it via web-portal for example

  -- Superseeded by boostrap-sw module !!!
  -- local hostname = "nodemcu" .. require("node").chipid()
  -- local mac = require("wifi").ap.getmac()
  -- fs("wifi-sta"):default("hostname", hostname):default("mac", mac):done()
  -- fs("wifi-ap"):default("config.ssid", hostname .. "_ap"):default("mac", mac):done()


  -- TODO add here your other hardcoded settings if you want to
end

return main
