--[[
    Temperature sensor.
]]
local modname = ...

---@param changes relay_switch_cfg_data as comming from HA request
local function main(changes)
    package.loaded[modname] = nil

    local log = require("log")
    log.info("change settings to %s", log.json, changes)
    require("relay-switch-control")(changes.is_on)
end

return main
