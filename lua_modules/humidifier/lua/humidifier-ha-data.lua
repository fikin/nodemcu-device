--[[
    Temperature sensor.
]]
local modname = ...

---@type humidifier_state
local state = require("state")("humidifier")

---@return web_ha_entity_data
local function getData()
    return {
        ["humidifier-fan"] = {
            is_on = state.fan_is_on,
        },
        ["humidifier-mistifier"] = {
            is_on = state.mistifier_is_on,
        },
        ["humidifier-door"] = {
            is_on = state.door_is_on,
        },
        ["humidifier-water"] = {
            native_value = state.current_water_level,
        },
        ["humidifier-temp"] = {
            native_value = state.current_temperature,
        },
        ["humidifier"] = {
            is_on = state.humidifier_is_on,
            action = state.action,
            current_humidity = state.current_humidity,
            target_humidity = state.target_humidity,
            max_humidity = 100, -- default values
            min_humidity = 0,   -- default values
            -- available_modes = { "" }, -- no support for modes
            -- mode = "",                -- no support for modes
            supported_features = 0, -- no supprot for modes
        },
    }
end

---@return web_ha_entity_data
local function main()
    package.loaded[modname] = nil

    return getData()
end

return main
