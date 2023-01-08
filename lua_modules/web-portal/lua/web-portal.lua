--[[
  Handles http requests related to Wifi portal web server.

  Called by http-srv.
]]
local modname = ...

---@param conn http_conn*
local function returnFile(conn)
  require("http-h-return-file")(conn)
end

---@param conn http_conn*
local function handleRoot(conn)
  conn.req.url = "/wifi-portal.html" -- serve it under /
  returnFile(conn)
end

---@param conn http_conn*
local function returnDeviceSettings(conn)
  local moduleName = string.sub(conn.req.url, #"/wifi-portal-ds/" + 1)
  local cfg = require("device-settings")(moduleName)
  require("http-h-send-json")(conn, cfg)
end

---@param conn http_conn*
local function saveDeviceSettings(conn)
  local cfg = require("http-h-read-json")(conn)
  local moduleName = string.sub(conn.req.url, #"/wifi-portal-ds/")
  local builder = require("factory-settings")(moduleName)
  builder:mergeTblInto("", cfg)
  builder:done()
  conn.resp.code = "200"
end

---@param conn http_conn*
---@param method string
---@param pathPattern string
---@return boolean match
local function isPathMatch(conn, method, pathPattern)
  return string.find(conn.req.url, pathPattern) ~= nil
end

---@param conn http_conn*
---@param method string
---@param path string
---@return boolean
local function isPath(conn, method, path)
  return method == conn.req.method and path == conn.req.url
end

---checks the authentication and if ok handles it in nextFn
---@param nextFn conn_handler_fn
---@param conn http_conn*
---@return boolean
local function checkAuth(nextFn, conn)
  -- portal credentials
  ---@type http_h_auth
  local adminCred = require("device-settings")(modname)

  if require("http-authorize")(conn, adminCred) then
    nextFn(conn)
  end
  return true
end

---handle http request if it is Wifi portal rest apis related
---@param conn http_conn*
---@return boolean
local function main(conn)
  package.loaded[modname] = nil

  if isPath(conn, "GET", "/") then
    return checkAuth(handleRoot, conn)
  elseif isPath(conn, "GET", "/wifi-portal.js") or
      isPath(conn, "GET", "/wifi-portal.css") or
      isPath(conn, "GET", "/wifi-portal.html") then
    return checkAuth(returnFile, conn)
  elseif isPathMatch(conn, "GET", "/wifi%-portal%-ds/.*") then
    return checkAuth(returnDeviceSettings, conn)
  elseif isPathMatch(conn, "POST", "/wifi%-portal%-ds/.*") then
    return checkAuth(saveDeviceSettings, conn)
  else
    return false
  end
end

return main
