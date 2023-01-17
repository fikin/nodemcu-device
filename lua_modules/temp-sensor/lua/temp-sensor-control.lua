local modname = ...

---@return temp_sensor_cfg
local function getState()
    return require("state")("temp-sensor")
end

local state = getState()

---@param addr string
---@return string
local function addrToStr(addr)
    return string.format("%02X:%02X:%02X:%02X:%02X:%02X:%02X:%02X", addr:byte(1, 8))
end

---updates RTE state with given temp
---@param temp table as provided by ds18b20
local function updateTempState(temp)
    for addr, temp in pairs(temp) do
        state.data.native_value = temp
        require("log").info("temp of sensor %s is %f", addrToStr(addr), temp)
        break
    end
end

---call thermostat's control loop
local function applyControlLoop()
    local ds18b20 = require("ds18b20")
    updateTempState(ds18b20(state.pin))
end

local function main()
    package.loaded[modname] = nil
    applyControlLoop()
end

return main
