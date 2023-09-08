--[[
    Temperature sensor.
]]
local modname = ...

local moduleName = "sct013-sensor"
local log = require("log")
local i2c = require("i2c")
local ads1115 = require("ads1115")

---@class sct013_sensor_state_data
---@field native_value number

---@class sct013_sensor_state
---@field data sct013_sensor_state_data
---@field ads ads1115_instance

---@class sct013_sensor_cfg
---@field periodMs integer
---@field pinSda integer
---@field pinScl integer
---@field address integer

---@return sct013_sensor_state
local function getState()
    return require("state")(moduleName)
end

---call thermostat's control loop
local function applyControlLoop()
    local state = getState()
    local volt, _, _, _ = state.ads:read()
    volt = (state.data.native_value + volt) / 2 -- average value
    state.data.native_value = volt              -- TODO calculate as amps
end

---prepare initial RTE state out of device settings
---@param ads ads1115_instance
local function prepareRteState(ads)
    -- remember in RTE state
    require("state")(moduleName, {
        ads = ads,
        data = { native_value = 0.0 },
    })
end

---schedule repeating timer to control the thermostat
---@param cfg sct013_sensor_cfg
local function scheduleTimerLoop(cfg)
    log.debug("scheduling control loop")
    local tmr = require("tmr")
    local t = tmr:create()
    t:register(cfg.periodMs, tmr.ALARM_AUTO, applyControlLoop)
    if not t:start() then
        log.error("failed starting a timer")
    end
end

---setup ADS115 with SCT013 sensor attached to it
---@param cfg sct013_sensor_cfg
---@return ads1115_instance
local function setupAds1115(cfg)
    i2c.setup(0, cfg.pinSda, cfg.pinScl, i2c.SLOW)
    ads1115.reset()
    local ads0 = ads1115.ads1115(0, cfg.address)
    ads0:setting(ads1115.GAIN_4_096V, ads1115.DR_8SPS, ads1115.DIFF_0_1, ads1115.CONTINUOUS)

    return ads0
end

local function main()
    package.loaded[modname] = nil

    log.debug("starting up ...")

    ---@type sct013_sensor_cfg
    local cfg = require("device-settings")(moduleName)

    local adsArr = setupAds1115(cfg)
    prepareRteState(adsArr)
    applyControlLoop()

    scheduleTimerLoop(cfg)
end

return main
