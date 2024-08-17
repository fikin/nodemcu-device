--[[
Common code to create device function.

It recognizes following common options from settings:

- cache: boolean, default false, if true, then device function will be cached
- pollingMs: integer, default 0, how often to poll device read and store the result in RTE state
]]
local modname = ...

---common device settings supported by this code generator
---@class device_common_dev_cfg:table
---@field cache boolean|nil should keep function in require cache
---@field pollingMs integer|nil polling interval in ms, calling device read function periodically
---@field filterSize integer|nil filter size, if present, then filter will be applied to the readings
---rest are funcname specific settings

---generate device main code, which is polling read function
---@param fncname string
---@param code string
---@param condcode string is_on condition code
---@return string
local function getPollingCode(fncname, code, condcode)
  return string.format([[
%s
local function polling(changes, setup)
  local state = getState()
  if setup then
    local tmr = require("tmr")
    state.tmr = tmr.create()
    state.tmr:register(settings._pollingMs, tmr.ALARM_AUTO, newreading)
    state._poll = %s(changes, setup)
  elseif changes then
    if %s then
      state.tmr:start()
    else
      state.tmr:stop()
    end
    state._poll = %s(changes, setup)
  end
  return state._poll
end
]],
    code,
    fncname,
    condcode,
    fncname
  )
end

---@param fncname string
---@param code string
---@return string
local function getFilterCode(fncname, code)
  return string.format([[
%s
local function filter(changes, setup)
  local state = getState()
  if setup then
    state._filter = %s(changes, setup)
  else
    local value = %s(changes)
    state._filter = (state._filter * (settings.filterSize - 1) + value) / settings.filterSize
  end
  return state._filter
end
]], code,
    fncname,
    fncname
  )
end

---@param devModuleName string
---@param name string
---@param settings table
---@return string
local function getDirectCode(devModuleName, name, settings)
  return string.format([[
local function getState()
  return require("state")("dev-%s")
end
local settings = %s
local function direct(...)
  return require("%s")("%s", settings, ...)
end
]], name,
    require("table-tostring")(settings),
    devModuleName, 
    name)
end

---@param fncname string
---@param code string
---@return string
local function getNonCachingMainCode(fncname, code)
  return string.format([[
local modname = ...
%s
local function main(...)
  package.loaded[modname] = nil
  return %s(...)
end
return main
]], code, fncname)
end

---@param fncname string
---@param code string
---@return string
local function getCachingMainCode(fncname, code)
  return string.format([[
%s
local function main(...)
  return %s(...)
end
return main
]], code, fncname)
end

---comment
---@param reqname string
---@param name string
---@param settings device_common_dev_cfg
---@param condcode string|nil polling is_on condition code e.g. "changes.is_on"
---@return string
local function getCode(reqname, name, settings, condcode)
  local fncname, code = "direct", getDirectCode(reqname, name, settings)
  if settings.filterSize then
    fncname, code = "filter", getFilterCode(fncname, code)
  end
  if settings.pollingMs then
    assert(condcode, "pollingMs requires condcode to be provided")
    fncname, code = "polling", getPollingCode(fncname, code, condcode)
  end
  if settings.cache then
    return getCachingMainCode(fncname, code)
  else
    return getNonCachingMainCode(fncname, code)
  end
end

---create ds-<name> lua file
---@param reqname string actual device-xxx function implementing this device type
---@param name string device name
---@param settings device_common_dev_cfg device settings
---@param condcode string|nil polling is_on condition code e.g. "changes.is_on"
local function main(reqname, name, settings, condcode)
  package.loaded[modname] = nil

  local code = getCode(reqname, name, settings, condcode)
  require("save-code")(string.format("dev-%s", name), code, true)
end

return main
