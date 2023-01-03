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

---update device settings with new directives from HA
---@param changes table
local function updateDevSettings(changes)
  local builder = require("factory-settings")

  if changes["target_temperature_high"] then
    -- copy temp range to preset modes structure too
    local activePresetMode = builder.get("%s.data.preset_mode" % modname)
    builder.mergeTblInto("%s.modes.%s" % { modname, activePresetMode }, changes)
  end
  builder.mergeTblInto("%s.data" % modname, changes)
  builder.done()
end

---updates RTE state with new changes
---@param changes table
local function updateState(changes)
  local state = require("state")(modname)
  require("table-merge")(state.data, changes)
end

---call thermostat's control loop
local function applyControlLoop()
  require("thermostat-control")()
end

---called by web_ha to handle HA commands
---@param changes table as comming from HA request
local function setFn(changes)
  local log = require("log")

  log.info("change settings to", log.json, changes)
  if changes["preset_mode"] or changes["hvac_mode"] or changes["target_temperature_high"] then
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
  local state = require("device-settings")(modname)

  -- remember in RTE state
  require("state")(modname, state)
end

---schedule repeating timer to control the thermostat
local function scheduleTimerLoop()
  local state = require("state")(modname)
  local tmr = require("tmr")
  local t = tmr:create()
  t:register(state.periodMs, tmr.ALARM_AUTO, applyControlLoop)
  if not t:start() then
    require("log").error("failed starting a timer")
  end
end

---prepares RTE state and schedules control loop
---registers to web_ha as HA climate entity
local function main()
  package.loaded[modname] = nil

  prepareRteState()
  applyControlLoop()

  scheduleTimerLoop()

  -- register HA entity
  local spec = {
    key = modname,
    name = "Thermostat"
  }
  local ptrToData = require("state")(modname).data
  require("web-ha-entity")(modname, "climate", spec, ptrToData, setFn)
end

return main
