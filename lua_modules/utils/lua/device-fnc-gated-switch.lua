--[[
Device function to control "gate" device (another switch)
by using schedule and input device (binary sensor) to decide on outcome.

This device being set on/off means enabling/disabling control loop itself.
]]

local modname = ...

---@class device_gated_switch_cfg
---@field scheduleMs integer
---@field sensorId string
---@field switchId string
---@field is_on boolean

---@class device_gated_switch_state
---@field is_on boolean
---@field tmr tmr_instance

---@param name string
---@return device_gated_switch_state
local function getState(name)
  return require("state")(string.format("dev-%s", name), {
    is_on = false,
    tmr = nil,
  })
end

---@param name string
---@param changes hass_switch_changes
local function doSetOnOff(name, changes)
  assert(changes.is_on ~= nil, string.format("400: is_on is required for '%s'", name))
  assert(type(changes.is_on) == "boolean", string.format("400: is_on must be boolean for '%s'", name))
  local log = require("log")
  log.debug("device %s : setting to %s", name, changes.is_on and "on" or "off")
  if changes.is_on then
    getState(name).tmr:start()
  else
    getState(name).tmr:stop()
  end
end

---@param name string
---@param settings device_gated_switch_cfg
local function doSetup(name, settings)
  local tmr = require("tmr")
  local sensorDevName = string.format("dev-%s", settings.sensorId)
  local switchDevName = string.format("dev-%s", settings.switchId)
  local state = getState(name)
  state.tmr = tmr.create()
  state.tmr:register(settings.scheduleMs, tmr.ALARM_AUTO, function()
    local sensorState = require(sensorDevName)()
    local switchFn = require(switchDevName)
    local switchState = switchFn()
    if sensorState ~= switchState then
      switchFn({ is_on = sensorState })
    end
  end)
end

---@param name string
---@param settings device_gated_switch_cfg
local function assertSettings(name,settings)
  assert(settings.sensorId, string.format("400: sensorId is required for device '%s'", name))
  assert(settings.switchId, string.format("400: switchId is required for device '%s'", name))
end

---switch as control loop based on timer schedule, underlying switch
---and gate as binary_sensor.
---@param name string
---@param settings device_gated_switch_cfg
---@param changes hass_switch_changes|nil if given
---@param setup boolean|nil if given
---@return unknown
local function main(name, settings, changes, setup)
  package.loaded[modname] = nil

  if setup then
    assertSettings(name, settings)
    doSetup(name, settings)
    if settings.is_on then
      changes = { is_on = true }
    end
  end

  if changes then
    doSetOnOff(name, changes)
  end

  return getState(name).is_on
end

return main
