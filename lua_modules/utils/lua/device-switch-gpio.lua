--[[
Implements HASS switch logic
]]

local modname = ...

local gpio = require("gpio")

---account for inversion of value
---@param inverted boolean
---@param value boolean
---@return boolean
local function toInverted(inverted, value)
  return inverted and not value or value
end

---@param name string
---@param settings device_switch_cfg
---@param changes hass_switch_changes
local function onChange(name, settings, changes)
  assert(changes.is_on ~= nil, string.format("400: is_on is required for '%s'", name))
  assert(type(changes.is_on) == "boolean", string.format("400: is_on must be boolean for '%s'", name))
  local log = require("log")
  log.debug("device %s : setting to %s", name, changes.is_on and "on" or "off")
  gpio.write(settings.pin, toInverted(settings.inverted, changes.is_on) and gpio.HIGH or gpio.LOW)
end

---HASS switch device
---@param name string
---@param settings device_switch_cfg
---@param changes hass_switch_changes|nil if given
---@param setup boolean perform initial setup and ignore changes
---@return boolean
local function main(name, settings, changes, setup)
  if not settings.cache then
    package.loaded[modname] = nil
  end

  if setup then
    gpio.mode(settings.pin, gpio.OUTPUT, settings.set_float and gpio.FLOAT or gpio.PULLUP)
    if settings.is_on then
      changes = { is_on = true }
    end
  end
  if changes then
    onChange(name, settings, changes)
  end
  return toInverted(settings.inverted, gpio.HIGH == gpio.read(settings.pin))
end

return main
