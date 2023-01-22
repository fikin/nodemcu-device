--[[
    Temperature sensor.
]]
local modname = ...

---@param isOn boolean
---@return relay_switch_cfg state
local function prepareState(isOn)
    ---@type relay_switch_cfg
    local state = require("device-settings")("lights-switch")
    state.data.is_on = isOn

    require("state")("lights-switch", state)
    return state
end

---@param changes relay_switch_cfg_data as comming from HA request
local function main(changes)
    package.loaded[modname] = nil

    local log = require("log")
    log.info("change settings to %s", log.json, changes)

    local state = prepareState(changes.is_on)
    require("gpio-set-pin")(state.pin, state.data.is_on)
end

return main
