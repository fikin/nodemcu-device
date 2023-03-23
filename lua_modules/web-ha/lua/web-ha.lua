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

---@class web_ha_settings
---@field credentials http_h_auth
---@field entities string[]

---returns HA DataInfo structure
---@param conn http_conn*
local function getInfo(conn)
  local data = {
    manufacturer = "fikin",
    name = require("wifi").sta.gethostname(),
    model = "WeMos D1 mini",
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
    ---@type fun():web_ha_entity_specs
    local fn = require(key .. "-ha-spec")
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
    ---@type fun():web_ha_entity_data
    local fn = require(key .. "-ha-data")
    if fn and type(fn) == "function" then
      for k, v in pairs(fn()) do
        data[k] = v
      end
    end
  end
  require("http-h-send-json")(conn, data)
end

local function updateEntities(data)
  for k, v in pairs(data) do
    local fn = require(k .. "-ha-set")
    if fn and type(fn) == "function" then
      fn(v)
    else
      error(string.format("400: setting %s is not possible, there is no handler for it", k))
    end
  end
end

---set data for some HA entity
---@param conn http_conn*
---@param entities string[] list with entities defined in device settings
local function setData(conn, entities)
  local data = require("http-h-read-json")(conn)
  updateEntities(data)
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
  local state = require("state")(modname, nil, true)
  if state == nil then
    local cfg = require("device-settings")(modname)
    state = require("state")(modname, cfg)
  end
  return state
end

---checks the authentication and if ok handles it in nextFn
---@param nextFn fun(conn: http_conn*,entities:string[])
---@param conn http_conn*
---@return boolean
local function checkAuth(nextFn, conn)
  local cfg = getSettings()
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

  if isPath(conn, "GET", "/api/ha/info") then
    return checkAuth(getInfo, conn)
  elseif isPath(conn, "GET", "/api/ha/spec") then
    return checkAuth(getSpec, conn)
  elseif isPath(conn, "GET", "/api/ha/data") then
    return checkAuth(getData, conn)
  elseif isPath(conn, "POST", "/api/ha/data") then
    return checkAuth(setData, conn)
  else
    return false
  end
end

return main
