--[[
Creates a device of HASS type "switch" delegating to a configurable function.
]]

local modname = ...

---@class device_switch_fnc_cfg:device_common_dev_cfg
---@field funcname string
---@field cache boolean|nil should keep function in require cache
---@field pollingMs integer|nil polling interval in ms, calling device read function periodically
---@field is_on boolean|nil initial state of the switch, set during setup
---rest are funcname specific settings

---@param name string
---@param spec hass_spec
local function createSpec(name, spec)
  assert(spec.name, string.format("spec.name is required for %s", name))
  local data = {
    type = "switch",
    spec = {
      key          = name,
      name         = spec.name,
      device_class = spec.device_class or "switch",
    }
  }
  require("table-toluafile")(string.format("dev-spec-%s", name), data, true, true)
end

---@param settings device_switch_fnc_cfg
---@return string
local function getFncName(settings)
  return string.format("device-%s", settings.funcname)
end

---@param name string
---@param settings device_switch_fnc_cfg
local function assertSettings(name, settings)
  assert(settings.funcname, string.format("settings.funcname is required for device '%s'", name))

  local fncname = getFncName(settings)
  assert(pcall(require, fncname), string.format("function '%s' not found for device '%s'", fncname, name))
end

---create device with given name and settings
---@param name string
---@param spec hass_spec
---@param settings device_switch_fnc_cfg
local function main(name, spec, settings)
  package.loaded[modname] = nil

  assertSettings(name, settings)
  createSpec(name, spec)
  require("device-factory-dev")(getFncName(settings), name, settings, "changes.is_on")
end

return main
