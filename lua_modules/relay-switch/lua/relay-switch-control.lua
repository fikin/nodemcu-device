local modname = ...

---@return relay_switch_cfg
local function getState()
    return require("state")("relay-switch")
end

---turns relay based on flag
---@param isOn boolean
local function ensureIs(isOn)
    package.loaded[modname] = nil

    local state = getState()
    local gpio = require("gpio")
    local log = require("log")

    gpio.mode(state.pin, gpio.OUTPUT)
    gpio.write(state.pin, isOn and gpio.HIGH or gpio.LOW)
    state.data.is_on = isOn
    log.info("set gpio pin %d to %s", state.pin, state.data.is_on and "HIGH" or "LOW")
end

return ensureIs
