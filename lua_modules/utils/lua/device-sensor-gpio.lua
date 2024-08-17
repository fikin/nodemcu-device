--[[
Plain simple digital input as HASS binary_sensor.
]]

local modname = ...

local gpio = require("gpio")

---read gpio input now
---@param cfg device_gpio_input_cfg
---@return boolean
local function readInput(cfg)
  return gpio.read(cfg.pin) == (cfg.inverted and gpio.LOW or gpio.HIGH)
end

---@param name string
---@return boolean[]
local function getState(name)
  return require("state")(string.format("ds-%s", name))
end

---debouncing logic, waits for the input to stabilize
---@param name string
---@param cfg device_gpio_input_cfg
local function waitForChange(name, cfg)
  local tmr = require("tmr")

  local function updateState()
    local val = readInput(cfg)
    if getState(name)[0] ~= val then
      local log = require("log")
      log.debug("device %s : changed to %s", name, val)
      getState(name)[0] = val
    end
  end

  local function startDebounce()
    gpio.trig(cfg.pin, "none", nil)
    updateState()
    tmr.create():alarm(cfg.debounceMs, tmr.ALARM_SINGLE, function()
      updateState()
      gpio.trig(cfg.pin, "both", startDebounce)
    end)
  end

  updateState()
  gpio.trig(cfg.pin, "both", startDebounce)
end

---plain simply gpio input sensor
---@param name string name
---@param settings device_gpio_input_cfg
---@param _ table|nil changes
---@param setup boolean
---@return boolean
local function main(name, settings, _, setup)
  if not settings.cache then
    package.loaded[modname] = nil
  end

  if setup then
    gpio.mode(settings.pin, gpio.INPUT, settings.set_float and gpio.FLOAT or gpio.PULLUP)
    if settings.debounceMs > 0 then
      waitForChange(name, settings)
    end
  end
  if settings.debounceMs > 0 then
    return getState(name)[0]
  else
    return readInput(settings)
  end
end

return main
