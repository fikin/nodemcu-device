local modname = ...

---@class humidifier_cfg
---@field target_humidity number
---@field is_on boolean

---@class humidifier_state
---@field action string one of "humidifying", "drying", "idle", "off"
---@field current_humidity number
---@field current_temperature number
---@field current_water_level number

---@return humidifier_cfg
local function getState()
    ---@type humidifier_cfg
    local cfg = require("device-settings")("humidifier")
    --cfg.current_humidity
    return cfg
end


local function controllLoop()
end

local function main(operation)
    if operation == "control" then
        controllLoop()
    end
end

return main
