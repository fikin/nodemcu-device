--[[
Factory for creating devices and device information.
]]

local modname = ...

local log = require("log")

---as HASS device info
---@class hass_info
---@field manufacturer  string
---@field name          string
---@field model         string
---@field swVersion     string
---@field hwVersion     string

---as HASS device specification
---@alias hass_spec table

---device specification
---@class device_spec
---@field name      string
---@field type      string
---@field internal  boolean -- if true, device is not exposed to HASS
---@field spec      hass_spec|nil
---@field settings  table|nil

---definitions of all devices inside the system
---@class device_defs
---@field info hass_info
---@field devices device_spec[]

---@param info hass_info
local function saveDeviceInfo(info)
  local fs = require("factory-settings")("dev-info")
  fs.cfg = {
    manufacturer = info.manufacturer or "Noname vendor",
    name         = info.name or require("wifi").sta.gethostname(),
    model        = info.model or "Generic NodeMCU make",
    swVersion    = info.swVersion or require("get-sw-version")().version,
    hwVersion    = info.hwVersion or "1.0.0",
  }
  fs:done()
end

---@param devices device_spec[]
local function saveDevicesList(devices)
  local arr = {}
  for _, device in ipairs(devices) do
    table.insert(arr, device.name)
  end
  local fs = require("factory-settings")("dev-list")
  fs.cfg = arr
  fs:done()
end

---@param devices device_spec[]
local function saveDevicesHassList(devices)
  local arr = {}
  for _, device in ipairs(devices) do
    if not device.internal then
      table.insert(arr, device.name)
    end
  end
  local fs = require("factory-settings")("dev-hass-list")
  fs.cfg = arr
  fs:done()
end

---@param dev device_spec
local function saveDevice(dev)
  assert(dev.name, "device name is required")
  assert(dev.type, string.format("device type is required for '%s'", dev.name))
  assert(dev.internal ~= nil, string.format("device internal flag is required for '%s'", dev.name))

  if dev.name == "info" or dev.name == "list" or dev.name == "hass-list" then
    error("device name cannot be 'info' or 'list'")
  end
  local ok, fn = pcall(require, string.format("device-factory-%s", dev.type))
  if not ok then
    error(string.format("device type '%s' not supported for '%s'", dev.type, dev.name))
  end
  log.info("creating device : %s (%s)", dev.name, dev.type)
  fn(dev.name, dev.spec or {}, dev.settings or {})
end

---@param devices device_spec[]
local function saveDevices(devices)
  for _, device in ipairs(devices) do
    saveDevice(device)
  end
end

---create devices out of definitions
---@param defs device_defs
local function main(defs)
  package.loaded[modname] = nil

  saveDeviceInfo(defs.info)
  saveDevices(defs.devices)
  saveDevicesList(defs.devices)
  saveDevicesHassList(defs.devices)
end

return main
