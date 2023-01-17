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
    return require("state")("temp-sensor")
end

---call thermostat's control loop
local function applyControlLoop()
    require("temp-sensor-control")()
end

---prepare initial RTE state out of device settings
local function prepareRteState()
    ---@type temp_sensor_cfg
    local state = require("device-settings")("temp-sensor")

    -- by default 22C, until reading happens
    state.data = { native_value = 22 }

    -- remember in RTE state
    require("state")("temp-sensor", state)
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

local function main()
    package.loaded[modname] = nil

    log.debug("starting up ...")

    prepareRteState()
    applyControlLoop()

    scheduleTimerLoop()
end

return main
