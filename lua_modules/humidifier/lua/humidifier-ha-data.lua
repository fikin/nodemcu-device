--[[
    Temperature sensor.
]]
local modname = ...

local state = require("state")("humidifier")

---@return web_ha_entity_data
local function getData()
    return {
        ["humidifier-fan"] = {
            is_on = state("fan-is-on"),
        },
        ["humidifier-mistifier"] = {
            is_on = state("mistifier-is-on"),
        },
        ["humidifier-door"] = {
            is_on = state("door-is-open"),
        },
        -- ["humidifier-water"] = {
        --     native_value = state("water-level"),
        -- },
        -- ["humidifier-water-is-low"] = {
        --     native_value = state("water-level-is-low"),
        -- },
        ["humidifier-temperature"] = {
            native_value = state("temperature"),
        },
        ["humidifier"] = {
            is_on = state("is-on"),
            action = state("action"),
            current_humidity = state("humidity"),
            target_humidity = state("target-humidity"),
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
