local modname = ...

---@return temp_sensor_cfg
local function getState()
    return require("state")("temp-sensor")
end

---updates RTE state with given temp
---@param temp table as provided by ds18b20
local function updateTempState(temp)
    local state = getState()
    for addr, temp in pairs(temp) do
        state.data.native_value = temp
        require("log").info("temp of sensor %02X:%02X:%02X:%02X:%02X:%02X:%02X:%02X is %f", addr:byte(1, 8), temp)
        break
    end
end

---call thermostat's control loop
local function applyControlLoop()
    local state = getState()
    local ds18b20 = require("ds18b20")
    ds18b20:read_temp(updateTempState, state.pin, ds18b20.C)
end

local function main()
    package.loaded[modname] = nil
    applyControlLoop()
end

return main
