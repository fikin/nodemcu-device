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

-- update device settings (i.e. remember the state)
local function updateDevSettings(changes)
  local b = require("factory_settings")

  if changes["target_temperature_high"] then
    local state = require("device_settings")(modname)
    b.mergeTblInto("%s.modes.%s" % {modname, state.data.preset_mode}, changes)
  else
    b.mergeTblInto("%s.data" % modname, changes)
  end
  b.done()
end

local function applyControlLoop()
  require("thermostat_control")()
end

local function setFn(changes)
  local tm = require("table_merge")
  local log = require("log")
  local state = require("device_settings")(modname)

  log.info("change settings to", log.json, changes)
  if changes["preset_mode"] or changes["hvac_mode"] or changes["target_temperature_high"] then
    tm(state.data, changes) -- update RTE state
    updateDevSettings(changes)
    applyControlLoop()
  else
    log.error("ignoring the change, thermostat is not supporting it")
  end
end

local function prepareRteState()
  -- read device settings into RTE state variable
  local state = require("device_settings")(modname)

  -- assign supported modes
  state.data.preset_modes = {}
  for k, _ in pairs(state.modes) do
    table.insert(state.data.preset_modes, k)
  end

  -- copy active mode int data state
  require("table_merge")(state.data, state.modes[state.data.preset_mode])

  -- remember in RTE state
  require("state")(modname, state)
end

local function scheduleTimerLoop()
  local state = require("state")(modname)
  local tmr = require("tmr")
  local t = tmr:create()
  t:register(state.periodMs, tmr.ALARM_AUTO, applyControlLoop)
  if not t:start() then
    require("log").error("failed starting a timer")
  end
end

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
  require("web_ha_entity")(modname, "climate", spec, ptrToData, setFn)
end

return main
