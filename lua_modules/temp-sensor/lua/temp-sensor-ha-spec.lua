local modname = ...

---@return web_ha_entity_specs
local function main()
    package.loaded[modname] = nil

    return { { type = "sensor", spec = {
        key                        = "temp-sensor",
        name                       = "Temperature",
        device_class               = "temperature",
        native_unit_of_measurement = "°C",
        state_class                = "measurement",
    } } }
end

return main
