--[[
    Current (amps) sensor.
]]
local modname = ...

---@return web_ha_entity_data
local function main()
    package.loaded[modname] = nil

    ---@type sct013_sensor_state
    local cfg = require("state")("sct013-sensor")
    return { ["sct013-sensor-0-current"] = cfg.data }
end

return main
