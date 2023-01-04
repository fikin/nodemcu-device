--[[
    Temperature sensor.
]]
local modname = ...

local log = require("log")

---@class temp_sensor_cfg_data
---@field native_value number

---@class temp_sensor_cfg
---@field periodMs integer
---@field pin integer
---@field data temp_sensor_cfg_data

---@return temp_sensor_cfg
local function getState()
    return require("state")(modname)
end

---updates RTE state with given temp
---@param temp table as provided by ds18b20
local function updateTempState(temp)
    local state = getState()
    for addr, temp in pairs(temp) do
        state.data.native_value = temp
        log.debug("temp of sensor %02X:%02X:%02X:%02X:%02X:%02X:%02X:%02X is %f", addr:byte(1, 8), temp)
        break
    end
end

---call thermostat's control loop
local function applyControlLoop()
    local state = getState()
    local ds18b20 = require("ds18b20")
    ds18b20:read_temp(updateTempState, state.pin, ds18b20.C)
end

---prepare initial RTE state out of device settings
local function prepareRteState()
    -- read device settings into RTE state variable
    ---@type temp_sensor_cfg
    local state = require("device-settings")(modname)
    state.data = { native_value = 22 } -- by default 22C, until reading happens

    -- remember in RTE state
    require("state")(modname, state)
end

---schedule repeating timer to control the thermostat
local function scheduleTimerLoop()
    log.debug("scheduling control loop")
    local state = getState()
    local tmr = require("tmr")
    local t = tmr:create()
    t:register(state.periodMs, tmr.ALARM_AUTO, applyControlLoop)
    if not t:start() then
        log.error("failed starting a timer")
    end
end

---register Home Assistant entity
local function registerHAentity()
    -- register HA entity
    local spec = {
        key                        = modname,
        name                       = "Temperature",
        device_class               = "temperature",
        native_unit_of_measurement = "°C",
        state_class                = "measurement",
    }
    local ptrToData = getState().data
    require("web-ha-entity")(modname, "sensor", spec, ptrToData, nil)
end

local function main()
    package.loaded[modname] = nil

    log.debug("starting up ...")

    prepareRteState()
    applyControlLoop()

    scheduleTimerLoop()

    registerHAentity()
end

return main
