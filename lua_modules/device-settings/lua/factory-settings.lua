--[[
  Builder of device settings.

  Stores the modified settings in ds-module.json file.

  Usage:
    local builder = require("factory-settings")("wifi-sta")

    builder.set("hostname","telnet").set("config.ssid","myHotSpot")

    builder.done()

  Use this module to assign device settings programmatically.
]]
local modname = ...

local file = require("file")
local sjson = require("sjson")

---saves text into file using intermediate fName.bak file
---@param txt string
---@param fName string
local function safeSaveJsonFile(txt, fName)
  require("log").info("updating device settings %s", fName)
  -- saving is using .tmp and .bak
  local fTmp, fBak = fName .. ".tmp", fName .. ".bak"
  file.remove(fTmp)
  if not file.putcontents(fTmp, txt) then
    error(string.format("failed saving %s", fTmp))
  end
  file.remove(fBak)
  if file.exists(fName) and not file.rename(fName, fBak) then
    error(string.format("failed renaming %s to %s", fName, fBak))
  end
  if not file.rename(fTmp, fName) then
    error(string.format("failed renaming %s to %s", fTmp, fName))
  end
  file.remove(fBak)
end

---checks the given existingValue and decides if to return that or defValue
---decision is based on existingValue being empty, nil or in template form "<..>".
---@param existingValue string|boolean|number|table|nil to check
---@param defValue string|number|boolean|table|nil to return if existingValue is considered unset
---@return string|number|boolean|table|nil
local function getDefaultValue(existingValue, defValue)
  -- is it factory template value
  if not existingValue or
      (type(existingValue) == "string" and
          (#existingValue == 0 or string.find(existingValue, "<[%w_]+>")))
  then
    return defValue
  end
  return existingValue
end

---recursively travers parent until child field is found and returned.
---all ancestors in child are either already existing in parent
---or are being created as part of the traversal.
---@param parent table is the data to search for child field
---@param child string is descendant path to return
---@param fullpath? string is full path we're lookign for, used for reporting purposes only
---@return string|boolean|number|table|nil is the value representing child inside the parent
---@return table is direct parent (ancestor) of the last field of the child (if path) or child itself
---@return string it is either last child of the path or child itself
local function get(parent, child, fullpath)
  fullpath = fullpath or child
  local sP, eP = string.find(child, "%.")
  if sP then
    local key = string.sub(child, 1, eP - 1)
    local nextKey = string.sub(child, eP + 1)
    local v = parent[key]
    if type(v) == "table" then
      -- drill down the hierarchy of the search path
      return get(v, nextKey, fullpath)
    elseif v then
      error(string.format("can't get %s because field %s is atomic and not a table", fullpath, key))
    else
      -- create new table and continue drilling down the structure
      parent[key] = {}
      return get(parent[key], nextKey, fullpath)
    end
  else
    -- found the end of search path
    return parent[child], parent, child
  end
end

---checks if cfg is empty and if so saves nothing.
---@param cfg table
---@param fName string
local function saveDeviceSettings(cfg, fName)
  local txt = assert(sjson.encode(cfg))
  if txt == "[]" then
    file.remove(fName) -- empty device settings, no need to save them
  else
    if file.exists(fName) then
      local txt2 = file.getcontents(fName)
      if txt == txt2 then return; end -- same files, no need to write
    end
    safeSaveJsonFile(txt, fName)
  end
end

---compares cfg against factory settings
---@param cfg table
---@param moduleName string
local function saveCfgIfChanged(cfg, moduleName)
  local cfgFS = require("device-settings")(moduleName, true)
  require("table-substract")(cfg, cfgFS)
  saveDeviceSettings(cfg, string.format("ds-%s.json", moduleName))
end

---Builder interface towards factory settings.
---@class factory_settings*
local M = {
  ---module name
  ---@private
  moduleName = "",
  ---module's factory settings configuration
  cfg = {}
}
M.__index = M

---instantiate new factory settings builder instance
---@param moduleName string
---@return factory_settings*
local function newM(moduleName)
  local o = setmetatable({
    moduleName = moduleName,
    cfg = require("device-settings")(moduleName),
  }, M)
  return o
end

-- saves settings if any value was changed
---@param self factory_settings*
M.done = function(self)
  saveCfgIfChanged(self.cfg, self.moduleName)
end

---sets the field to given value, unconditionally.
---@param self factory_settings*
---@param field any to assign value to. it can be hierarchical path i.e. attr.attr...
---@param value any value to assign to the field.
---@return factory_settings*
M.set = function(self, field, value)
  local _, parent, child = get(self.cfg, field)
  parent[child] = value
  return self
end

-- sets the field to given value only if settings value is:
---   empty
---   not set or
---   string in the form "<[%w_]+>"
---assignment is unconditional, like if involked by set()
---@param self factory_settings*
---@param field any to assign value to. it can be hierarchical path i.e. attr.attr...
---@param value any value to assign to the field.
---@return factory_settings*
M.default = function(self, field, value)
  local v, parent, child = get(self.cfg, field)
  parent[child] = getDefaultValue(v, value)
  return self
end

-- sets the field to nil
---@param self factory_settings*
---@param field any to assign value to. it can be hierarchical path i.e. attr.attr...
---@return factory_settings*
M.unset = function(self, field)
  local _, parent, child = get(self.cfg, field)
  parent[child] = nil
  return self
end

-- gets the field value or nil if not defined
---@param self factory_settings*
---@param field any to get the value of. it can be hierarchical path i.e. attr.attr...
---@return table|string|number|boolean|nil
M.get = function(self, field)
  local ret, _, _ = get(self.cfg, field)
  return ret
end

-- sets the field to given tbl
-- it merges the content, any other data if field is preserved
-- it scans tbl recursively i.e. deep merge
---@param self factory_settings*
---@param field? string to get the value of. it can be hierarchical path i.e. attr.attr...
---@param tbl table to assign the the field. internally it is using table_merge().
---@return factory_settings*
M.mergeTblInto = function(self, field, tbl)
  if field then
    local _, parent, child = get(self.cfg, field)
    parent[child] = parent[child] or {}
    require("table-merge")(parent[child], tbl)
  else
    require("table-merge")(self.cfg, tbl)
  end
  return self
end

---instantiate new factory settings builder
---@param moduleName string
---@return factory_settings*
local function main(moduleName)
  package.loaded[modname] = nil -- gc

  return newM(moduleName)
end

return main
