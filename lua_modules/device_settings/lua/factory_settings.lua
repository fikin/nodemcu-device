--[[
  Builder of "device-settings.json" during factory settings.

  Usage:
    local builder = require("factory_settings")

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
      error("failed renaming %s to %s" % {fName, fBak})
    end
    if not file.rename(fTmp, fName) then
      error("failed renaming %s to %s" % {fTmp, fName})
    end
  end
end

local function getDefaultValue(existingValue, defValue)
  -- is it factory template value
  if
    not existingValue or (type(existingValue) == "string" and #existingValue == 0) or
      (existingValue and string.find(existingValue, "<[%w_]+>"))
   then
    return defValue
  else
    return existingValue
  end
end

local function set(cfg, field, setValFn, fullpath)
  local sP, eP = string.find(field, "%.")
  if sP then
    local key = string.sub(field, 1, eP - 1)
    local nextKey = string.sub(field, eP + 1)
    local v = cfg[key]
    if type(v) == "table" then
      set(v, nextKey, setValFn, fullpath or field) -- drill down the structure
    elseif v then
      error("can't set value to %s because field %s is atomic and not a table" % {fullpath, key})
    else -- create new table and continue drilling down the structure
      cfg[key] = {}
      set(cfg[key], nextKey, setValFn, fullpath or field)
    end
  else
    -- found the leaf field
    cfg[field] = setValFn(cfg[field])
  end
end

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
      error("can't get %s because field %s is atomic and not a table" % {fullpath, key})
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

local fName = "device-settings.json"

local M = {
  cfg = require("read_json_file")(fName)
}

-- saves settings if any value was changed
M.done = function()
  saveCfgIfChanged(M.cfg, fName)
  package.loaded[modname] = nil -- gc
end

-- loads factory-settings.json
M.loadFactorySettings = function()
  local tbl = require("read_json_file")("factory-settings.json")
  require("table_merge")(M.cfg, tbl)
end

-- sets the field to given value, unconditionally
M.set = function(field, value)
  local _, parent, child = get(M.cfg, field)
  parent[child] = value
end

-- sets the field to given value only if:
-- settings value is empty, not set or in the form "<[%w_]+>"
M.default = function(field, value)
  local v, parent, child = get(M.cfg, field)
  parent[child] = getDefaultValue(v, value)
end

-- sets the field to nil
M.unset = function(field)
  local _, parent, child = get(M.cfg, field)
  parent[child] = nil
end

-- gets the field value or nil if not defined
M.get = function(field)
  return get(M.cfg, field)
end

-- sets the field to given tbl
-- it merges the content, any other data if field is preserved
-- it scans tbl recursively i.e. deep merge
M.mergeTblInto = function(field, tbl)
  local _, parent, child = get(M.cfg, field)
  parent[child] = parent[child] or {}
  require("table_merge")(parent[child], tbl)
end

return M
