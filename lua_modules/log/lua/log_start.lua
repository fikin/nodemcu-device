local modname = ...

local function main()
  package.loaded[modname] = nil
  -- configure logger state with device settings
  require("state")().log = require("device_settings")("log")
end

return main
