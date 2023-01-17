--[[
  Control loop of the thermostat
]]
local modname = ...

local log = require("log")

---@type thermostat_cfg
local state = require("state")("thermostat")

---decode hvac_action text out of pinLevel and hvac_mode
---@param isOn boolean pin level where gpio.HIGH means on
---@return string as per hvac_action
local function determineHvacAction(isOn)
  if isOn then
    return "heating"
  elseif state.data.hvac_mode == "off" then
    return "off"
  else
    return "idle"
  end
end

---assign gpio pin level and hvac_action
---@param isOn boolean
local function setRealy(isOn)
  local action = determineHvacAction(isOn)
  state.data.hvac_action = action
  log.info("setting hvac action to %s, mode is %s", action, state.data.hvac_mode)
  require("gpio-set-pin")(state.relayPin, isOn)
end

---turns heating on
local function ensureIsOn()
  setRealy(true)
end

---turns heating off
local function ensureIsOff()
  setRealy(false)
end

---turns heating on if temp is below LOW and off if temp is above HIGH
local function ensureIsAuto()
  if state.data.current_temperature >= state.data.target_temperature_high then
    ensureIsOff()
  elseif state.data.current_temperature <= state.data.target_temperature_low then
    ensureIsOn()
  end
end

---decides what to do based on hvac_mode
local function handleHvacMode()
  local mode = state.data.hvac_mode
  if mode == "off" then
    ensureIsOff()
  elseif mode == "on" then
    ensureIsOn()
  elseif mode == "auto" then
    ensureIsAuto()
  else
    log.error("unsupported hvac_mode mode %s", mode)
    ensureIsOff()
  end
end

local function readLatestTemp()
  state.data.current_temperature = require("temp-sensor-get")()
end

---starts a temp reading and on its success it triggers a control loop
local function main()
  package.loaded[modname] = nil

  readLatestTemp()
  handleHvacMode()
end

return main
