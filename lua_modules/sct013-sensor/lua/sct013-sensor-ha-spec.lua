local modname = ...

---@return web_ha_entity_specs
local function main()
    package.loaded[modname] = nil

    return { {
        type = "sensor",
        spec = {
            key                        = "sct013-sensor",
            name                       = "Current",
            device_class               = "current",
            native_unit_of_measurement = "A",
            state_class                = "measurement",
        }
    } }
end

return main
