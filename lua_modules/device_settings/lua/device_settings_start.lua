--[[
  Called by bootprotect to setup device settings during device start up.

  Call this fairly early on, before someone is using device-settings.
]]
local modname = ...

local function main()
  package.loaded[modname] = nil

  -- device config, factory settings
  local builder = require("factory_settings")

  -- updates the settings from OTA update via factory-settings.json
  builder.loadFactorySettings()

  -- apply user defined factory settings
  require("user_settings")(builder)

  -- persist settings (if there would be a need)
  builder.done()
end

return main
