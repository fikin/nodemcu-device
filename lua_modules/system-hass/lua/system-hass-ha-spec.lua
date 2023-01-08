local modname = ...

---@return web_ha_entity_specs
local function main()
    package.loaded[modname] = nil

    return {
        { type = "sensor", spec = {
            key                        = "system-heap-sensor",
            name                       = "Heap",
            device_class               = "data_size",
            native_unit_of_measurement = "B",
            state_class                = "measurement",
        } },
        { type = "button", spec = {
            key          = "system-restart-button",
            name         = "Restart",
            device_class = "restart",
        } },
    }
end

return main
