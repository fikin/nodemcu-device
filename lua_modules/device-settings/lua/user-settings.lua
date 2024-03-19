--[[
  Add here device settings which you want to
  apply programmatically at boot time each time.

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

---place to provide with device specific hardcoded device settings.
---feel free to modify the settings here, boot sequence will ensure
---the data is properly handled in device settings.
local function main()
  package.loaded[modname] = nil

  -- local fs = require("factory-settings")

  -- TODO add here your other hardcoded settings if you want to
end

return main
