--[[
Creates a device of HASS type "switch" controlling GPIO pin.
]]

local modname = ...

---settings of a single switch
---@class device_switch_cfg:device_common_dev_cfg
---@field pin integer
---@field inverted boolean|nil should gpio values be inverted
---@field set_float boolean|nil should setup set it to FLOAT instead of PULLUP
---@field is_on boolean|nil initial state of the switch, set during setup

---HASS switch changes payload
---@class hass_switch_changes
---@field is_on boolean

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

---@param name string
---@param settings device_switch_cfg
local function assertSettings(name, settings)
  assert(settings.pin, string.format("pin is required for device '%s'", name))
end

---create device with given name and settings
---@param name string
---@param spec hass_spec
---@param settings device_switch_cfg
local function main(name, spec, settings)
  package.loaded[modname] = nil

  assertSettings(name, settings)
  createSpec(name, spec)
  require("device-factory-dev")("device-switch-gpio", name, settings, "changes.is_on")
end

return main
