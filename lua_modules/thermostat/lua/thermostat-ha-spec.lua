local modname = ...

---returns HASS entity spec
---@return web_ha_entity_specs
local function main()
  package.loaded[modname] = nil

  return { { type = "climate", spec = {
    key = "thermostat",
    name = "Thermostat"
  } } }
end

return main
