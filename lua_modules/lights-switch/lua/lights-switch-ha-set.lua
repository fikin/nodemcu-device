--[[
    Temperature sensor.
]]
local modname = ...

---@param changes relay_switch_cfg_data as comming from HA request
local function main(changes)
    package.loaded[modname] = nil

    local log = require("log")
    log.info("change settings to %s", log.json, changes)

    ---@type lights_switch_cfg
    local state = require("state")("lights-switch")
    state.data.is_on = changes.is_on
    require("gpio-set-pin")(state.pin, state.data.is_on)
end

return main
