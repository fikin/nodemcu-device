--[[
  Setup web rest endpoints for HomeAssistant integration.

  This is the enabler functionalty, setting up NodeMCU-Device platform endpoints.

  Content of what actual HA entities this devices exports are defined via:
    require("web-haentity").setSpec()
]]
local modname = ...

---@class web_ha_entity_spec
---@field type string HASS entity type like "climate" or "sensor"
---@field spec table HASS entity specification

---set of entity specs
---@alias web_ha_entity_specs web_ha_entity_spec[]

---set of entity data, keys must be globally unique!
---@alias web_ha_entity_data {[string]:any}

--- <module>-ha.spec function signature
---@alias web_ha_spec_fn fun():web_ha_entity_specs

--- <module>-ha.set function signature
---@alias web_ha_set_fn fun(data:web_ha_entity_data):boolean

---- <module>-ha-get function signature
---@alias web_ha_get_fn fun():web_ha_entity_data

---@class web_ha_settings
---@field credentials http_h_auth
---@field entities string[]

---lookup of -ha-spec function
---@param moduleName string
---@return web_ha_spec_fn
local function getSpecFn(moduleName)
  return require(moduleName .. "-ha-spec")
end

---lookup of -ha-get function
---@param moduleName string
---@return web_ha_get_fn
local function getDataFn(moduleName)
  return require(moduleName .. "-ha-data")
end

---lookup of -ha-set function
---@param moduleName string
---@return web_ha_set_fn|nil
local function getSetFn(moduleName)
  local ok, fn = pcall(require, moduleName .. "-ha-set")
  if ok then return fn end
  return nil
end

---list keys as csv
---@param tbl table
---@return string
local function listKeys(tbl)
  local keys = {}
  for key, _ in pairs(tbl) do
    table.insert(keys, key)
  end
  return table.concat(keys, ", ")
end

---returns HA DataInfo structure
---@param conn http_conn*
local function getInfo(conn)
  local data = {
    manufacturer = "Noname vendor",
    name = require("wifi").sta.gethostname(),
    model = "Generic NodeMCU make",
    swVersion = require("get-sw-version")().version,
    hwVersion = "1.0.0"
  }
  require("http-h-send-json")(conn, data)
end

---return HA entity specifications
---@param conn http_conn*
---@param entities string[] list with entities defined in device settings
local function getSpec(conn, entities)
  local data = {}
  for _, key in ipairs(entities) do
    local fn = getSpecFn(key)
    if fn and type(fn) == "function" then
      for _, spec in ipairs(fn()) do
        ---@cast spec web_ha_entity_spec
        data[spec.type] = data[spec.type] or {}
        table.insert(data[spec.type], spec.spec)
      end
    else
      error("500: missing HASS entity spec for " .. key)
    end
  end
  require("http-h-send-json")(conn, data)
end

---return HA entities data
---@param conn http_conn*
---@param entities string[] list with entities defined in device settings
local function getData(conn, entities)
  local data = {}
  for _, key in ipairs(entities) do
    local fn = getDataFn(key)
    if fn and type(fn) == "function" then
      for k, v in pairs(fn()) do
        if data[k] then
          error("500: dublicate key found " .. key .. " from module " .. key)
        end
        data[k] = v
      end
    else
      error("500: missing implementation for HASS module " .. key)
    end
  end
  require("http-h-send-json")(conn, data)
end

local function updateEntities(data, entities)
  local found = false
  for _, key in ipairs(entities) do
    local fn = getSetFn(key)
    if fn and type(fn) == "function" then
      found = fn(data) or found
    end
  end
  if not found then
    error("500: no module recognized key(s) from " .. listKeys(data))
  end
end

---set data for some HA entity
---@param conn http_conn*
---@param entities string[] list with entities defined in device settings
local function setData(conn, entities)
  local data = require("http-h-read-json")(conn)
  updateEntities(data, entities)
  conn.resp.code = "200"
end

---@param conn http_conn*
---@param method string
---@param path string
---@return boolean
local function isPath(conn, method, path)
  return method == conn.req.method and path == conn.req.url
end

---read settings, they are cached in state for faster parsing
---@return web_ha_settings
local function getSettings()
  return require("device-settings")(modname)
end

---checks the authentication and if ok handles it in nextFn
---@param cfg web_ha_settings
---@param nextFn fun(conn: http_conn*,entities:string[])
---@param conn http_conn*
---@return boolean
local function checkAuth(cfg, nextFn, conn)
  if require("http-authorize")(conn, cfg.credentials) then
    nextFn(conn, cfg.entities)
  end
  return true
end

---handle http request if it is Home Assistant rest apis related
---@param conn http_conn*
---@return boolean
local function main(conn)
  package.loaded[modname] = nil

  local cfg = getSettings()

  if isPath(conn, "GET", "/api/ha/info") then
    return checkAuth(cfg, getInfo, conn)
  elseif isPath(conn, "GET", "/api/ha/spec") then
    return checkAuth(cfg, getSpec, conn)
  elseif isPath(conn, "GET", "/api/ha/data") then
    return checkAuth(cfg, getData, conn)
  elseif isPath(conn, "POST", "/api/ha/data") then
    return checkAuth(cfg, setData, conn)
  else
    return false
  end
end

return main
