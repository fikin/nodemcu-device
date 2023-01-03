--[[
  Builder of "device-settings.json" during factory settings.

  Usage:
    local builder = require("factory-settings")

    builder.set("sta.hostname","telnet").set("sta.config.ssid","myHotSpot")

    if #builder.cfg.ap.ssid == 0 then builder.cfg.ap.ssid = "NodeMCU" end

    builder.done()

  Use this module to assign device settings programmatically.

  If "device-settings.json" contains values in the form "<some name>" 
    can be set intially via "builder.set(key,value)".
    Once set, these values can be modified by web-portal 
    but not changed by factory settings code.

  One can assign values directly to settings via "builder.cfg.<field> = value".
    Such assignment is absolute i.e. changes via web-portal would be reverted back.
]]
local modname = ...

---checks if the config differs form the one in the file and saves it if so.
---@param cfg table to save if differing from fName content
---@param fName string of the file name with persisted content
local function saveCfgIfChanged(cfg, fName)
  local file, sjson, crypto, encoder = require("file"), require("sjson"), require("crypto"), require("encoder")
  local txt = sjson.encode(cfg)
  local txtMD5 = encoder.toHex(crypto.hash("MD5", txt))
  local fMD5 = encoder.toHex(crypto.fhash("MD5", fName))
  if txtMD5 ~= fMD5 then
    require("log").info("updating device settings")
    -- saving is using .tmp and .bak
    local fTmp, fBak = fName .. ".tmp", fName .. ".bak"
    file.remove(fTmp)
    if not file.putcontents(fTmp, txt) then
      error("failed saving %s" % fTmp)
    end
    file.remove(fBak)
    if not file.rename(fName, fBak) then
      error("failed renaming %s to %s" % { fName, fBak })
    end
    if not file.rename(fTmp, fName) then
      error("failed renaming %s to %s" % { fTmp, fName })
    end
    file.remove(fBak)
  end
end

-- local function set(cfg, field, setValFn, fullpath)
--   local sP, eP = string.find(field, "%.")
--   if sP then
--     local key = string.sub(field, 1, eP - 1)
--     local nextKey = string.sub(field, eP + 1)
--     local v = cfg[key]
--     if type(v) == "table" then
--       set(v, nextKey, setValFn, fullpath or field) -- drill down the structure
--     elseif v then
--       error("can't set value to %s because field %s is atomic and not a table" % { fullpath, key })
--     else -- create new table and continue drilling down the structure
--       cfg[key] = {}
--       set(cfg[key], nextKey, setValFn, fullpath or field)
--     end
--   else
--     -- found the leaf field
--     cfg[field] = setValFn(cfg[field])
--   end
-- end

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
      error("can't get %s because field %s is atomic and not a table" % { fullpath, key })
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

---the file name containing device settings.
---at device initialization phase i.e. firmware flash,
---the content is copied as-is from factory-settings.json.
---after that moment, it is maintained continuously.
---@type string
local fName = "device-settings.json"

---factory settings file, shipped with sw package
---@type string
local fNameFactory = "factory-settings.json"

---reads device-settings.json
---if it does not exists, it copies factory-settings.json
---@return table
local function loadSettingsFile()
  local file = require("file")
  if file.exists(fName) then
    return require("read-json-file")(fName)
  else
    if file.putcontents(fName, file.getcontents(fNameFactory)) then
      return loadSettingsFile()
    else
      error("failed to create " .. fName)
    end
  end
end

---Builder interface towards factory settings.
---@class factory_settings*
local M = {
  ---@type table factory settings
  cfg = loadSettingsFile()
}

-- saves settings if any value was changed
M.done = function()
  saveCfgIfChanged(M.cfg, fName)
  package.loaded[modname] = nil -- gc
end

---loads factory-settings.json
---this is called typically as part of sw upgrade sequence only
M.loadFactorySettings = function()
  local tbl = require("read-json-file")(fNameFactory)
  require("table-merge")(M.cfg, tbl)
end

---sets the field to given value, unconditionally.
---@param field any to assign value to. it can be hierarchical path i.e. attr.attr...
---@param value any value to assign to the field.
M.set = function(field, value)
  local _, parent, child = get(M.cfg, field)
  parent[child] = value
end

-- sets the field to given value only if settings value is:
---   empty
---   not set or
---   string in the form "<[%w_]+>"
---assignment is unconditional, like if involked by set()
---@param field any to assign value to. it can be hierarchical path i.e. attr.attr...
---@param value any value to assign to the field.
M.default = function(field, value)
  local v, parent, child = get(M.cfg, field)
  parent[child] = getDefaultValue(v, value)
end

-- sets the field to nil
---@param field any to assign value to. it can be hierarchical path i.e. attr.attr...
M.unset = function(field)
  local _, parent, child = get(M.cfg, field)
  parent[child] = nil
end

-- gets the field value or nil if not defined
---@param field any to get the value of. it can be hierarchical path i.e. attr.attr...
---@return table|string|number|boolean|nil
M.get = function(field)
  local ret, _, _ = get(M.cfg, field)
  return ret
end

-- sets the field to given tbl
-- it merges the content, any other data if field is preserved
-- it scans tbl recursively i.e. deep merge
---@param field any to get the value of. it can be hierarchical path i.e. attr.attr...
---@param tbl any to assign the the field. internally it is using table_merge().
M.mergeTblInto = function(field, tbl)
  local _, parent, child = get(M.cfg, field)
  parent[child] = parent[child] or {}
  require("table-merge")(parent[child], tbl)
end

return M
