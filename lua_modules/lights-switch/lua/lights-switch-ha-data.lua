--[[
    Temperature sensor.
]]
local modname = ...

---@return web_ha_entity_data
local function main()
    package.loaded[modname] = nil

    ---@type lights_switch_cfg
    local cfg = require("device-settings")("lights-switch")

    cfg.data.is_on = require("relay")(cfg.relay)()

    return { ["lights-switch"] = cfg.data }
end

return main
