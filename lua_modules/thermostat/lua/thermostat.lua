--[[
  Start up for thermostat.

  In device-settings.json:
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
  return require("state")(modname)
end

---update device settings with new directives from HA
---@param changes thermostat_cfg_change
local function updateDevSettings(changes)
  local builder = require("factory-settings")

  if changes.target_temperature_high then
    -- copy temp range to preset modes structure too
    local activePresetMode = builder.get(string.format("%s.data.preset_mode", modname))
    builder.mergeTblInto(string.format("%s.modes.%s", modname, activePresetMode), changes)
  end
  builder.mergeTblInto(string.format("%s.data", modname), changes)
  builder.done()
end

---updates RTE state with new changes
---@param changes thermostat_cfg_change
local function updateState(changes)
  local state = getState()
  require("table-merge")(state.data, changes)
end

---call thermostat's control loop
local function applyControlLoop()
  require("thermostat-control")()
end

---called by web_ha to handle HA commands
---@param changes thermostat_cfg_change as comming from HA request
local function setFn(changes)
  local log = require("log")

  log.info("change settings to %s", log.json, changes)
  if changes.preset_mode or changes.hvac_mode or changes.target_temperature_high then
    updateState(changes)
    updateDevSettings(changes)
    applyControlLoop()
  else
    log.error("ignoring the change, thermostat is not supporting it")
  end
end

---prepare initial RTE state out of device settings
local function prepareRteState()
  -- read device settings into RTE state variable
  ---@type thermostat_cfg
  local state = require("device-settings")(modname)

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
    key = modname,
    name = "Thermostat"
  }
  local ptrToData = getState().data
  require("web-ha-entity")(modname, "climate", spec, ptrToData, setFn)
end

---prepares RTE state and schedules control loop
---registers to web_ha as HA climate entity
local function main()
  package.loaded[modname] = nil

  log.debug("starting up ...")

  prepareRteState()
  applyControlLoop()

  scheduleTimerLoop()

  registerHAentity()
end

return main
