--[[
  Start up for thermostat.

  In device settings:
    - preset target temps are stored in own attribute ("modes")
    - active preset and hvac modes are in "data"
    - current temp is RTE data only

  In RTE state: device settings is stored as-is with exception of:
    - current temp is placed in "data"
    - active preset target temps are copied from "modes" to "data"
  This way "data" is directly returned to HA.
]]
local modname = ...

local log = require("log")

---@class thermostat_cfg_mode_cfg
---@field target_temperature_high integer
---@field target_temperature_low integer

---@class thermostat_cfg_mode
---@field away thermostat_cfg_mode_cfg
---@field day thermostat_cfg_mode_cfg
---@field night thermostat_cfg_mode_cfg

---@class thermostat_cfg_data
---@field temperature_unit string
---@field target_temperature_high integer
---@field target_temperature_low integer
---@field hvac_mode string
---@field hvac_modes string[]
---@field preset_mode string
---@field preset_modes string[]
---@field supported_features integer

---@class thermostat_cfg
---@field periodMs integer
---@field tempSensorPin integer
---@field relayPin integer
---@field modes thermostat_cfg_mode[]
---@field data thermostat_cfg_data

---@class thermostat_cfg_change
---@field preset_mode? string
---@field hvac_mode? string
---@field target_temperature_high? string
---@field target_temperature_low? string

---@return thermostat_cfg
local function getState()
  return require("state")("thermostat")
end

---call thermostat's control loop
local function applyControlLoop()
  require("thermostat-control")()
end

---prepare initial RTE state out of device settings
local function prepareRteState()
  -- read device settings into RTE state variable
  ---@type thermostat_cfg
  local state = require("device-settings")("thermostat")

  -- remember in RTE state
  require("state")("thermostat", state)
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

---prepares RTE state and schedules control loop
---registers to web_ha as HA climate entity
local function main()
  package.loaded[modname] = nil

  log.debug("starting up ...")

  prepareRteState()
  applyControlLoop()

  scheduleTimerLoop()
end

return main