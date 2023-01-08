local modname = ...

local hassKey = "thermostat"

---@return thermostat_cfg
local function getState()
  return require("state")(hassKey)
end

---update device settings with new directives from HA
---@param changes thermostat_cfg_change
local function updateDevSettings(changes)
  local builder = require("factory-settings")(hassKey)

  if changes.target_temperature_high then
    -- copy temp range to preset modes structure too
    local activePresetMode = builder:get("data.preset_mode")
    builder:mergeTblInto(string.format("modes.%s", activePresetMode), changes)
  end
  builder:mergeTblInto("data", changes)
  builder:done()
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

---handle HASS command (service) request
---@param data table HASS command payload
local function main(data)
  package.loaded[modname] = nil

  setFn(data)
end

return main
