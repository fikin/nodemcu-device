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
    local addrsCnt = 0
    for addr, temp in pairs(temp) do
        if addrsCnt > 1 then
            log.info("temp sensor %s (%f°C) is ignored, only one sensor is supported", addr, temp)
        else
            -- pass new value over avg filter logic
            state.data.native_value = (state.data.native_value * (state.filterSize - 1) + temp) / state.filterSize
            log.info("temp of sensor %s is : %f°C : new reading is %f°C", addr, state.data.native_value, temp)
        end
        addrsCnt = addrsCnt + 1
    end
    if addrsCnt == 0 then
        log.error("no temp sensor readings provided : %s", log.json, temp)
    end
end

---call thermostat's control loop
local function applyControlLoop()
    local m = require(state.moduleName)
    m(updateTempState)
end

local function main()
    package.loaded[modname] = nil
    applyControlLoop()
end

return main
