--[[
  Called by bootprotect to setup device settings during device start up.

  Call this fairly early on, before someone is using device-settings.
]]
local modname = ...

---called by bootprotect to upgrade device-settings.json
---with all new defaults (after sw upgrade) from factory-settings.json
---and applies all user hardcoded settings.
local function main()
  package.loaded[modname] = nil

  -- device config, factory settings
  local builder = require("factory-settings")

  -- updates the settings from OTA update via factory-settings.json
  builder.loadFactorySettings()

  -- apply user defined factory settings
  require("user-settings")(builder)

  -- persist settings (if there would be a need)
  builder.done()
end

return main
