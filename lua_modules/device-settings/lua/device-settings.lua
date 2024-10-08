--[[
  Reads module device settings stored in "ds-module.json".

  Use this module to read configuation and use it wherever needed.

  Usage:
    local cfg = require("device-settings")("wifi")
    print(cfg.country.country) -- prints device country
]]
local modname = ...

local file = require("file")

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
  return loadJsonFile(string.format("fs-%s.json", moduleName))
end

---reads ds-modulename.json
---@param moduleName string
---@return table
local function loadDeviceSettings(moduleName)
  return loadJsonFile(string.format("ds-%s.json", moduleName))
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

---load compiled device settings ds-%.lc if exists.
---if not, it reads ds-%.json and fs-%.json and merges them.
---@param moduleName string
---@return table
local function loadCompiledDeviceSettings(moduleName)
  -- local fName = string.format("ds-%s.lc", moduleName)
  -- if file.exists(fName) then
  --   return assert(load(file.getcontents(fName) or ""))()
  -- end
  local ok, fn = pcall(require, string.format("ds-%s", moduleName))
  if ok then return fn() end
  return loadModuleSettings(moduleName)
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
  return loadCompiledDeviceSettings(moduleName)
end

return main
