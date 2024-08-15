--[[
Creates a device of HASS type "switch" controlling GPIO pin.
]]

local modname = ...

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
---@param settings table
local function createDev(name, settings)
  local code = string.format([[
local modname = ...
local function main(...)
  package.loaded[modname] = nil
  return require("device-switch-gpio")("%s", %s, ...)
end
return main
]],
    name,
    require("table-tostring")({
      pin       = assert(settings.pin, string.format("pin is required for '%s'", name)),
      inverted  = settings.inverted or false,
      set_float = settings.set_float or false,
    })
  )
  require("save-code")(string.format("dev-%s",name), code, true)
end

---create device with given name and settings
---@param name string
---@param spec hass_spec
---@param settings table
local function main(name, spec, settings)
  package.loaded[modname] = nil

  createSpec(name, spec)
  createDev(name, settings)
end

return main
