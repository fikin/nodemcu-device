local modname = ...

---returns HASS entity data
---@return web_ha_entity_data
local function main()
  package.loaded[modname] = nil

  ---@type thermostat_cfg
  local cfg = require("state")("thermostat")
  return { thermostat = cfg.data }
end

return main
