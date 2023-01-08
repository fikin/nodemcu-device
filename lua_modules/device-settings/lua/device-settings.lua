--[[
  Reads module device settings stored in "ds-module.json".

  Use this module to read configuation and use it wherever needed.

  Usage:
    local cfg = require("device-settings")("wifi")
    print(cfg.country.country) -- prints device country
]]
local modname = ...

---loads a json file, it does not exists it returns empty table
---@param fName string
---@return table
local function loadJsonFile(fName)
  if file.exists(fName) then
    return require("read-json-file")(fName)
  end
  return {}
end

---reads ds-modulename.json
---@param moduleName string
---@return table
local function loadFactorySettings(moduleName)
  local o = loadJsonFile(string.format("fs-%s.json", moduleName))
  o.__mode = "k"
  return o
end

---reads ds-modulename.json
---@param moduleName string
---@return table
local function loadDeviceSettings(moduleName)
  local o = loadJsonFile(string.format("ds-%s.json", moduleName))
  o.__mode = "k"
  return o
end

---loads factort settings json and then merges device settings on top.
---@param moduleName string
---@return table
local function loadModuleSettings(moduleName)
  local cfg1 = loadFactorySettings(moduleName)
  local cfg2 = loadDeviceSettings(moduleName)
  require("table-merge")(cfg1, cfg2)
  return cfg1
end

---read device settings for given module name.
---it reads ds-modulename.json and merges it with fs-modulename.json.
---@param moduleName string
---@param factoryOnly? boolean to load factory settings only. this is used internally.
---@return table config
local function main(moduleName, factoryOnly)
  package.loaded[modname] = nil

  if factoryOnly then
    return loadFactorySettings(moduleName)
  end
  return loadModuleSettings(moduleName)
end

return main
