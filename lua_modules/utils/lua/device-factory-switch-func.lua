--[[
Creates a device of HASS type "switch" delegating to a configurable function.
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

---@param settings table
---@return string
local function settingsToFnc(settings)
  local tbl = require("table-clone")(settings)
  tbl.funcname = nil
  return require("table-tostring")(tbl)
end

---@param name string
---@param fname string
---@return string
local function getFncName(name, fname)
  assert(fname, string.format("settings.funcname is required for %s", name))
  local fncname = string.format("device-%s", fname)
  assert(pcall(require, fncname), string.format("function '%s' not found for device '%s'", fncname, name))
  package.loaded[fncname] = nil -- gc
  return fncname
end

---@param name string
---@param settings table
local function createDev(name, settings)
  local fname = getFncName(name, settings.funcname)
  local code = string.format([[
local modname = ...
local function main(...)
  package.loaded[modname] = nil
  return require("%s")("%s", %s, ...)
end
return main
]],
    fname,
    name,
    settingsToFnc(settings)
  )
  require("save-code")(string.format("dev-%s", name), code, true)
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
