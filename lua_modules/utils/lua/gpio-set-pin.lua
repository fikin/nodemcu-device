local modname = ...

---turns GPIO pin HIGH is isOn true, lese LOW
---@param pin integer
---@param toHigh boolean
local function ensureIs(pin, toHigh)
    package.loaded[modname] = nil

    local gpio = require("gpio")
    local log = require("log")

    gpio.mode(pin, gpio.OUTPUT)
    gpio.write(pin, toHigh and gpio.HIGH or gpio.LOW)
    log.info("set gpio pin %d to %s", pin, toHigh and "HIGH" or "LOW")
end

return ensureIs
