--[[
  Control loop of the thermostat
]]
local modname = ...

local log, gpio = require("log"), require("gpio")

local state = require("state")("thermostat")

---decode hvac_action text out of pinLevel and hvac_mode
---@param pinLevel integer pin level where gpio.HIGH means on
---@return string as per hvac_action
local function determineHvacAction(pinLevel)
  if pinLevel == gpio.HIGH then
    return "heating"
  elseif state.data.hvac_mode == "off" then
    return "off"
  else
    return "idle"
  end
end

---assign gpio pin level and hvac_action
---@param level integer
local function setRealyPin(level)
  state.data.hvac_action = determineHvacAction(level)
  local gpio = require("gpio")
  gpio.mode(state.relayPin, gpio.OUTPUT)
  gpio.write(state.relayPin, level)
  log.debug(string.format("set gpio pin %d to %s", state.relayPin, level and "HIGH" or "LOW"))
end

---turns heating on
local function ensureIsOn()
  setRealyPin(gpio.HIGH)
end

---turns heating off
local function ensureIsOff()
  setRealyPin(gpio.LOW)
end

---turns heating on if temp is below LOW and off if temp is above HIGH
local function ensureIsAuto()
  if state.data.current_temperature > state.data.target_temperature_high then
    ensureIsOff()
  elseif state.data.current_temperature < state.data.target_temperature_low then
    ensureIsOn()
  end
end

---decides what to do based on hvac_mode
local function handleHvacMode()
  local mode = state.data.hvac_mode
  if mode == "off" then
    ensureIsOn()
  elseif mode == "on" then
    ensureIsOff()
  elseif mode == "auto" then
    ensureIsAuto()
  else
    log.error("unsupported hvac_mode mode %s" % mode)
    ensureIsOff()
  end
end

---updates RTE state with given temp
---@param temp table as provided by ds18b20
local function updateTempState(temp)
  for _, temp in pairs(temp) do
    state.data.current_temperature = temp
    log.debug("temp is %f" % temp)
    break
  end
end

---update temp and peform control loop decision
---@param temp table as provided by ds18b20
local function readoutTemp(temp)
  updateTempState(temp)
  handleHvacMode()
end

---starts a temp reading and on its success it triggers a control loop
local function main()
  package.loaded[modname] = nil

  local ds18b20 = require("ds18b20")
  ds18b20:read_temp(readoutTemp, state.tempSensorPin, ds18b20.C)
  package.loaded["ds18b20"] = nil
end

return main
