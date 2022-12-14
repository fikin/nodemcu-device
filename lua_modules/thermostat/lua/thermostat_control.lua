--[[
  TODO
]]
local modname = ...

local log = require("log")
local state = require("state")("thermostat")

local function setRealyPin(level)
  local gpio = require("gpio")
  gpio.mode(state.relayPin, gpio.OUTPUT)
  gpio.write(state.relayPin, level)
  log.debug("set gpio pin %d to %s" % {state.relayPin, level and "HIGH" or "LOW"})
end

local function ensureIsOn()
  setRealyPin(gpio.HIGH)
end

local function ensureIsOff()
  setRealyPin(gpio.LOW)
end

local function ensureIsAuto()
  if state.data.current_temperature > state.data.target_temperature_high then
    ensureIsOff()
  elseif state.data.current_temperature < state.data.target_temperature_low then
    ensureIsOn()
  end
end

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

local function updateTempState(temp)
  for _, temp in pairs(temp) do
    state.data.current_temperature = temp
    log.debug("temp is %f" % temp)
    break
  end
end

local function readoutTemp(temp)
  updateTempState(temp)
  handleHvacMode()
end

local function main()
  package.loaded[modname] = nil

  local ds18b20 = require("ds18b20")
  ds18b20:read_temp(readoutTemp, state.tempSensorPin, ds18b20.C)
  package.loaded["ds18b20"] = nil
end

return main
