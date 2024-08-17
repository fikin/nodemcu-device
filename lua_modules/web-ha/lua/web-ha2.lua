--[[
  Setup web rest endpoints for HomeAssistant integration.

  This is the enabler functionalty, setting up NodeMCU-Device platform endpoints.

  Content of what actual HA entities this devices exports are defined via:
    require("web-haentity").setSpec()
]]
local modname = ...

---device as function
---if changes are provided, then it is a set operation and return nothing.
---if changes are nil, then it is a get operation and return the current state.
---@alias device_fn fun(changes: table|nil)

---returns HA DataInfo structure
---@param conn http_conn*
local function getInfo(conn)
  local data = require("device-settings")("dev-info")
  require("http-h-send-json")(conn, data)
end

---list devices
---@return string[] list of devices
local function listDevices()
  return require("device-settings")("dev-hass-list")
end

---get device function by device name
---@param key string
---@param variant string|nil for get/set is nil, for spec it is "-spec"
---@return device_fn
local function getDeviceFn(key, variant)
  local ok, fn = pcall(require, string.format("dev-%s%s", variant, key))
  if ok then return fn end
  error("404: no device found for key " .. key)
end

---safe call of device function
---@param key string
---@param fn device_fn
---@param ... any
---@return any|nil
local function callDeviceFn(key, fn, ...)
  local ok, resp = pcall(fn, ...)
  if ok then return resp end
  error(string.format("500: device error : %s : %s", key, resp))
end

---return HA entity specifications
---@param conn http_conn*
local function getSpec(conn)
  local data = {}
  for _, k in listDevices() do
    local fn = getDeviceFn(k, "-spec")
    local v = callDeviceFn(k, fn)
    data[k] = v
  end
  require("http-h-send-json")(conn, data)
end

---return HA entities data
---@param conn http_conn*
local function getData(conn)
  local data = {}
  for _, k in listDevices() do
    local fn = getDeviceFn(k)
    local v = callDeviceFn(k, fn)
    data[k] = v
  end
  require("http-h-send-json")(conn, data)
end

---set data for some HA entity
---@param conn http_conn*
local function setData(conn)
  local data = require("http-h-read-json")(conn)
  for k, v in pairs(data) do
    local fn = getDeviceFn(k)
    callDeviceFn(k, fn, v)
  end
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
---@param nextFn fun(conn: http_conn*)
---@param conn http_conn*
---@return boolean
local function checkAuth(cfg, nextFn, conn)
  if require("http-authorize")(conn, cfg.credentials) then
    nextFn(conn)
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
