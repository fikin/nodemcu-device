local modname = ...

---@return web_ha_entity_specs
local function main()
    package.loaded[modname] = nil

    return {
        {
            type = "switch",
            spec = {
                key          = "humidifier-fan",
                name         = "Fan",
                device_class = "switch",
            }
        },
        {
            type = "switch",
            spec = {
                key          = "humidifier-mistifier",
                name         = "Mistifier",
                device_class = "switch",
            }
        },
        {
            type = "binary_sensor",
            spec = {
                key          = "humidifier-door",
                name         = "Door",
                device_class = "door",
            }
        },
        {
            type = "sensor",
            spec = {
                key                        = "humidifier-water",
                name                       = "Water Level",
                device_class               = "volume_storage",
                native_unit_of_measurement = "mL",
                state_class                = "measurement",
            }
        },
        {
            type = "sensor",
            spec = {
                key                        = "humidifier-temp",
                name                       = "Temperature",
                device_class               = "temperature",
                native_unit_of_measurement = "°C",
                state_class                = "measurement",
            }
        },
        {
            type = "humidifier",
            spec = {
                key          = "humidifier",
                name         = "Humidifier",
                device_class = "humidifier",
            }
        },
    }
end

return main
