local modname = ...

---@return temp_sensor_cfg
local function getState()
    return require("state")("temp-sensor")
end

local state = getState()

---updates RTE state with given temp
---@param temp table as provided by ds18b20
local function updateTempState(temp)
    local log = require("log")
    local moreThanOne = false
    for addr, temp in pairs(temp) do
        if moreThanOne then
            log.info("temp sensor %s (%f°C) is ignored, only one sensor over i2c bus is supported", addr, temp)
        else
            state.data.native_value = temp
            log.info("temp of sensor %s is %f°C", addr, temp)
        end
        moreThanOne = true
    end
end

---call thermostat's control loop
local function applyControlLoop()
    local ds18b20 = require("ds18b20")
    ds18b20(state.pin, updateTempState)
end

local function main()
    package.loaded[modname] = nil
    applyControlLoop()
end

return main
