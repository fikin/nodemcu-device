--[[
  Add here factory settings, not defined in the "factory-settings.json".
  
  Use builder.set("field path", value) to assign some value programmatically.
  Such a setting overwriting any different set via web-portal or provided in device-settings.json.
  
  Use builder.unset("field path") to set the field to nil.
  Like with set(), this setting is overwriting any previous different value.

  Use builder.default("field path", value) to assign some value, if not assigned already.
  This setting would take effect only if default-settings.json value is either:
  - not defined
  - empty string
  - string containing "<something>" format
  In all other cases (values), the value would not be changed.
  ]]
local modname = ...

---place to provide with device specific hardcoded device settings.
---feel free to modify the settings here, boot sequence will ensure
---the data is properly handled in device settings.
---@param builder factory_settings* to use to set device settings
local function main(builder)
  package.loaded[modname] = nil

  -- typically set hostname is based on chipID
  -- until user overwrites it via web-portal for example
  local hostname = "nodemcu" .. require("node").chipid()
  builder.default("sta.hostname", hostname)
  builder.default("ap.config.ssid", hostname .. "_ap")

  -- TODO add here your other hardcoded settings if you want to
end

return main
